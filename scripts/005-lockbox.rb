1. comment has_encrypted :settings, type: :hash

2.
---
result_post_endpoint: https://numeactivate.bubbleapps.io/version-test/api/1.1/wf/results

#<ApiAccount id: 2, username: "nume", password_digest: [FILTERED], contractor_id: 2, created_at: "2023-04-03 12:06:42.638791000 +0000", updated_at: "2023-06-01 08:39:20.936468000 +0000", settings: {"result_post_endpoint"=>"https://numeactivate.bubbleapps.io/version-test/api/1.1/wf/results"}, migrated_settings: nil>

[#<ApiAccount:0x00007ff92f955c38                                  
  id: 1,                                                          
  username: "epixpert",
  password_digest: "[FILTERED]",
  contractor_id: 1,
  created_at: Tue, 07 Mar 2023 21:35:58.734686000 UTC +00:00,
  updated_at: Mon, 27 Mar 2023 18:00:43.090581000 UTC +00:00,
  settings: {"result_post_endpoint"=>"http://localhost:5000/content"}>,
 #<ApiAccount:0x00007ff92f955d00
  id: 2,
  username: "nume",
  password_digest: "[FILTERED]",
  contractor_id: 3,
  created_at: Wed, 29 Mar 2023 13:24:15.721250000 UTC +00:00,
  updated_at: Wed, 29 Mar 2023 19:07:48.442161000 UTC +00:00,
  settings: {"result_post_endpoint"=>"http://localhost:5000/content"}>]

3
  # serialize :settings, type: Hash, coder: JSON, default: Hash.new
  has_encrypted :settings, type: :hash#, migrating: true

  Lockbox.migrate(ApiAccount)


https://github.com/ankane/lockbox#active-record