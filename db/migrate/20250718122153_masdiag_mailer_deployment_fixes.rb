class MasdiagMailerDeploymentFixes < ActiveRecord::Migration[7.1]
  def change
    # contractor_email_template_body fix
    Institution.where.not(contractor_email_template_body: nil).each do |i|
      body = i.contractor_email_template_body
      if body.include?("online_file_url")
        i.update(contractor_email_template_body: body.gsub("online_file_url", "b2b_online_file_url"))
      end
    end
    
  end
end
