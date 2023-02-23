# typed: false
# frozen_string_literal: true

{
  connection: {
    authorization: {
      type: 'custom_auth',

      apply: lambda do |settings|
        user(settings[:user])
        password(settings[:password])
      end
    },
    base_uri: lambda do
      'http://lvh.me:1080/'
    end
  },

  triggers: {
    test_trigger: {
      poll: lambda do |_settings, _input, closure|
        per_page = 2
        after_id = closure || 0
        posts = get('/posts').params(after_id: after_id, per_page: per_page)
        {
          events: posts,
          can_poll_more: posts.length >= per_page,
          next_poll: posts.any? ? posts.last['id'] : nil
        }
      end
    }
  }
}
