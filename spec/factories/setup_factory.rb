FactoryBot.define do
  factory :valid_setup_params, class: Hash do
    data do
    	{
        "url": "http://localhost:5000/content",
        "username": "yyyyy",
        "password": "xxxxxxxxx"
    	}
    end
    skip_create
    initialize_with { attributes }
  end
end