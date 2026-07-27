codes = %w[DNGW74 C382DF MY2NRD QG7UET 5BFHAM]

codes.each do |c|
	puts `curl -u 'masdiag:W8eJ@L$u^Cr7pH*8' https://my.cerascreen.de/api/tracking_codes/#{c}`
end
