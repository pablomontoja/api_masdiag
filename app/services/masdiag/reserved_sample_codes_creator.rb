class Masdiag::ReservedSampleCodesCreator < ApplicationService
  attr_accessor :packages
  attr_reader :prepared_reserved_sample_codes
  attr_reader :current_user

  def initialize(production_order, current_user)    
    @current_user = current_user
    @production_order = production_order
    @rsc_to_do_count = @production_order.packages.map {|pack| pack.product.capacity}.sum()
    @codes_used_before = (Sample.where("LENGTH(Code) = 5").pluck(:Code) + ReservedSampleCode.all.pluck(:Code)).uniq
  end

  def call
    begin      
      @production_order.packages.each do |pack|        
        pack.product.capacity.times {  
          code = get_random_code

          rsc = pack.reserved_sample_codes.build(Code: code, CreatedAt: Time.current, CreatedById: @current_user.id, IsRetailSale: 0, expiry_date: @production_order.packages_expiry_date.at_end_of_day, MaterialType: @production_order.product.material_type, material_handler: @production_order.product.material_handler)
          @codes_used_before.push(code)

        }         
      end   

      handle_result(@production_order)

    rescue StandardError => e
      Sentry.capture_exception(e)
      handle_error(e)
    end   
  end

private

  # sprawdza ostatni znak czy jest zgodny z sumą kontrolną
  def control_sum(code)
    return false if code.match?(/[oO0]/i)

    ul_sum = 0
    modulo34 = '123456789ABCDEFGHIJKLMNPQRSTUVWXYZ'
    (0..code.length - 2).step(2).each { |i| ul_sum += (code[i].ord - '1'.ord) * (i + 1) }
    ul_sum *= 3
    (1..code.length - 2).step(2).each { |i| ul_sum += (code[i].ord - '1'.ord) * i }
    controlchar = modulo34[ul_sum % 34]
    controlchar != code[-1]
  end

  # zwraca kod z dodatkowym znakiem (sumą kontrolną)
  def get_code_with_control_char(code)
    ul_sum = 0
    modulo34 = '123456789ABCDEFGHIJKLMNPQRSTUVWXYZ'
    (0..code.length - 1).step(2).each { |i| ul_sum += (code[i].ord - '1'.ord) * (i + 1) }
    ul_sum *= 3
    (1..code.length - 1).step(2).each { |i| ul_sum += (code[i].ord - '1'.ord) * i }
    controlchar = modulo34[ul_sum % 34]
    return "#{code}#{controlchar}"
  end

  def get_random_code
    is_invalid = true
    final_code = ""
    while is_invalid
      chars = ('A'..'Z').to_a - ['O']
      integers = (1..9).to_a 
      all_chars = chars + integers
      final_code = get_code_with_control_char(all_chars.shuffle[0,4].join)
      is_invalid = !is_code_valid?(final_code)
    end
    final_code  
  end

  def is_code_valid?(code)
    return false if is_i?(code)
    return false if @codes_used_before.include?(code)   
    return true
  end

  def is_i?(code)
     /\A[-+]?\d+\z/ === code
  end

end
