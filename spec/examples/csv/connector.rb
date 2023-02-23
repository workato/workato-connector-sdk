# typed: false
# frozen_string_literal: false

{
  title: 'csv',

  connection: {
    authorization: {
      type: 'none'
    }
  },

  test: lambda do
    true
  end,

  actions: {
    csv_generate: {
      execute: lambda do
        csv0 = workato.csv.generate do |csv|
          csv << [:blue, 1]
          csv << [:white, 2]
        end

        csv1 = workato.csv.generate(col_sep: ';') do |csv|
          csv << [:blue, 1]
          csv << [:white, 2]
        end

        csv2 = workato.csv.generate("color;count\n", col_sep: ';') do |csv|
          csv << [:blue, 1]
          csv << [:white, 2]
        end

        csv3 = workato.csv.generate(headers: %w[color amount], col_sep: ';') do |csv|
          csv << [:blue, 1]
          csv << [:white, 2]
        end

        { csv0: csv0, csv1: csv1, csv2: csv2, csv3: csv3 }
      end
    },

    csv_parse: {
      execute: lambda do
        csv1 = workato.csv.parse("blue;1\nwhite;2\n", headers: 'color;count', col_sep: ';')
        csv2 = workato.csv.parse("blue;1\nwhite;2\n", headers: [:color, 'count'], col_sep: ';')
        csv3 = workato.csv.parse("color;count\nblue;1\nwhite;2\n", headers: true, col_sep: ';')

        { csv1: csv1, csv2: csv2, csv3: csv3 }
      end
    }
  }
}
