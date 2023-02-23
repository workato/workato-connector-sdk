# typed: false
# frozen_string_literal: true

{
  pick_lists: {
    static: lambda do
      [
        %w[Meeting meeting],
        %w[Webinar webinar],
        ['Cloud recording', 'recording'],
        %w[User user]
      ]
    end,

    with_connection: lambda do |_connection|
      [
        %w[Meeting meeting],
        %w[Webinar webinar],
        ['Cloud recording', 'recording'],
        %w[User user]
      ]
    end,

    dependent_static: lambda do |_connection, index:|
      [
        %w[Meeting meeting],
        %w[Webinar webinar],
        ['Cloud recording', 'recording'],
        %w[User user]
      ][index]
    end,

    with_default_param: lambda do |_connection, index: 0|
      [
        %w[Meeting meeting],
        %w[Webinar webinar],
        ['Cloud recording', 'recording'],
        %w[User user]
      ][index]
    end,

    dependent_dynamic: lambda do |connection, index: 0|
      response = get('http://httpbin.org/anything')
                 .user(connection[:user])
                 .password(connection[:password])
                 .params(index: index)
      [
        %w[Meeting meeting],
        %w[Webinar webinar],
        ['Cloud recording', 'recording'],
        %w[User user]
      ][response.dig('args', 'index').to_i]
    end,

    tree: lambda do |_connection, index:, **args|
      tree = [
        ['Root', 'root', [
          %w[Meeting meeting],
          %w[Webinar webinar],
          ['Cloud recording', 'recording'],
          %w[User user]
        ].freeze]
      ].freeze
      if (parent_id = args&.[](:__parent_id))
        item = tree[parent_id][2][index]
        [[item[0], item[1], index, false]]
      else
        [[tree[0][0], tree[0][1], 0, true]]
      end
    end,

    companies: lambda { |connection|
      url = "https://#{connection['helpdesk']}.freshdesk.com/api/v2/companies.json"
      get(url).pluck('name', 'id')
    },

    contacts: lambda { |connection, company_id:|
      url = "https://#{connection['helpdesk']}.freshdesk.com/api/v2/contacts.json"
      get(url, company_id: company_id).pluck('name', 'id')
    }
  }
}
