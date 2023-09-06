# typed: false
# frozen_string_literal: true

RSpec.describe Enumerable do
  let :large_int do
    6_430_949_305_409_080_468
  end

  let :large_float do
    large_int + 0.5
  end

  let :list do
    [
      { a: 1, b: 2, c: 3, name: 'Don Martin' },
      { a: 1, b: 2, c: 4, name: 'Kevin N Clark' },
      { a: 1, b: 3, c: large_int, name: 'Jane Kelly' },
      { a: 1, b: 3, c: large_float, name: 'Jim Nolan' },
      { a: 2, b: 2, c: 3, name: 'Sofia Miller' },
      { a: 2, b: 2, c: 6, name: 'Kim Mossic' }
    ].map(&:with_indifferent_access)
  end

  let :workato_data_list do
    [
      ActiveSupport::HashWithIndifferentAccess.new(email: 'foo@bar.com'),
      ActiveSupport::HashWithIndifferentAccess.new(email: 'foo2@bar.com')
    ]
  end

  let :primitive_list do
    [1, 2, 3]
  end

  let :md_primitive_list do
    [[1, 2], [2, 3], [4, 5]]
  end

  let :invalid_list do
    [1]
  end

  describe 'to_csv' do
    it 'works with 1-d array' do
      expected = "1,2,3\n"
      list = [1, 2, 3]
      expect(list.to_csv(col_sep: ',', row_sep: "\n")).to eq(expected)
    end

    it 'works with 2-d array' do
      expected = "1,2,3\n4,5,6\n"
      list = [
        [1, 2, 3],
        [4, 5, 6]
      ]
      expect(list.to_csv(col_sep: ',', row_sep: "\n")).to eq(expected)
    end

    it 'works with 2-d array with multi_line=true' do
      expected = "1,2,3\n4,5,6\n"
      list = [
        [1, 2, 3],
        [4, 5, 6]
      ]
      expect(list.to_csv(col_sep: ',', row_sep: "\n", multi_line: true)).to eq(expected)
    end

    it 'works with 2-d array with multi_line=false' do
      expected = "\"[1, 2, 3]\",\"[4, 5, 6]\"\n"
      list = [
        [1, 2, 3],
        [4, 5, 6]
      ]
      expect(list.to_csv(col_sep: ',', row_sep: "\n", multi_line: false)).to eq(expected)
    end

    it 'works with 3-d array' do
      expected = "\"[1, 2, 3]\",\"[4, 5, 6]\"\n\"[7, 8, 9]\",\"[10, 11, 12]\"\n"
      list = [
        [[1, 2, 3], [4, 5, 6]],
        [[7, 8, 9], [10, 11, 12]]
      ]
      expect(list.to_csv(col_sep: ',', row_sep: "\n")).to eq(expected)
    end
  end

  describe 'format_map' do
    it 'handles empty/static format string' do
      expect(list.format_map('')).to eq(list)
      expect(list.format_map(nil)).to eq(list)
      expect(list.format_map('AA')).to eq(%w[AA AA AA AA AA AA])
    end

    it 'formats lists' do
      expect(primitive_list.format_map('A%1$s')).to eq(%w[A1 A2 A3])
      expect(md_primitive_list.format_map('%1$s:%2$s')).to eq(['1:2', '2:3', '4:5'])
      expect(list.format_map('%<a>s:%<b>s')).to eq(['1:2', '1:2', '1:3', '1:3', '2:2', '2:2'])
      expect(workato_data_list.format_map('Email:%<email>s')).to eq(['Email:foo@bar.com', 'Email:foo2@bar.com'])
    end
  end

  describe 'where' do
    it 'returns empty array for empty array' do
      expect([].where(id: 1).to_a).to eq([])
    end

    it 'returns empty array for non AR/non Hash arrays' do
      expect(invalid_list.where(id: 1).to_a).to eq([])
    end

    it 'returns object of type ArrayWhere' do
      expect([].where(a: 1).class).to eq(Workato::Extension::Array::ArrayWhere)
      expect(list.where(a: 1).class).to eq(Workato::Extension::Array::ArrayWhere)
      expect(workato_data_list.where(a: 1).class).to eq(Workato::Extension::Array::ArrayWhere)
      expect(invalid_list.where(id: 1).class).to eq(Workato::Extension::Array::ArrayWhere)
    end

    it 'returns valid array for Hash arrays' do
      expected_list = [
        { a: 1, b: 2, c: 3, name: 'Don Martin' },
        { a: 1, b: 2, c: 4, name: 'Kevin N Clark' },
        { a: 1, b: 3, c: large_int, name: 'Jane Kelly' },
        { a: 1, b: 3, c: large_float, name: 'Jim Nolan' }
      ].map(&:with_indifferent_access)
      expect(list.where(a: 1).to_a).to eq(expected_list)

      expected_list = [
        { a: 1, b: 2, c: 3, name: 'Don Martin' },
        { a: 2, b: 2, c: 3, name: 'Sofia Miller' }
      ].map(&:with_indifferent_access)
      expect(list.where(b: 2, c: 3).to_a).to eq(expected_list)

      expected_list = [
        { a: 1, b: 2, c: 3, name: 'Don Martin' },
        { a: 1, b: 2, c: 4, name: 'Kevin N Clark' },
        { a: 2, b: 2, c: 3, name: 'Sofia Miller' }
      ].map(&:with_indifferent_access)

      # symbol
      expect(list.where(b: 2, c: [3, 4]).to_a).to eq(expected_list)
      # string
      expect(list.where('b' => 2, 'c' => [3, 4]).to_a).to eq(expected_list)

      expect(list.where(b: 2, c: (3..4)).to_a).to eq(expected_list)
      # string
      expect(list.where('b' => 2, 'c' => (3..4)).to_a).to eq(expected_list)

      expected_list = [
        { a: 2, b: 2, c: 3, name: 'Sofia Miller' },
        { a: 2, b: 2, c: 6, name: 'Kim Mossic' }
      ].map(&:with_indifferent_access)
      expect(list.where.not(a: 1).to_a).to eq(expected_list)
      expect(list.where.not('a' => 1).to_a).to eq(expected_list)

      expected_list = [
        { a: 2, b: 2, c: 3, name: 'Sofia Miller' },
        { a: 2, b: 2, c: 6, name: 'Kim Mossic' }
      ].map(&:with_indifferent_access)
      expect(list.where('a >': 1).to_a).to eq(expected_list)
      expect(list.where('a >=': 1).to_a).to eq(list)

      expected_list = [
        { a: 1, b: 2, c: 3, name: 'Don Martin' },
        { a: 1, b: 2, c: 4, name: 'Kevin N Clark' },
        { a: 1, b: 3, c: large_int, name: 'Jane Kelly' },
        { a: 1, b: 3, c: large_float, name: 'Jim Nolan' }
      ].map(&:with_indifferent_access)
      expect(list.where('a <': 2).to_a).to eq(expected_list)
      expect(list.where('a <=': 2).to_a).to eq(list)

      expect(list.where('a <=': 2).to_a).to eq(list)
      expect(list.where('a !=': 2).to_a).to eq(expected_list)

      # Type conversion
      # when rhs is string
      expect(list.where('a <=': '2').to_a).to eq(list)
      # when lhs is string
      list2 = list.dup
      list2[0] = { a: '1', b: 2, c: 3, name: 'Don Martin' }.with_indifferent_access
      expected_list = [
        { a: '1', b: 2, c: 3, name: 'Don Martin' },
        { a: 1, b: 2, c: 4, name: 'Kevin N Clark' },
        { a: 1, b: 3, c: large_int, name: 'Jane Kelly' },
        { a: 1, b: 3, c: large_float, name: 'Jim Nolan' }
      ].map(&:with_indifferent_access)
      expect(list2.where('a <': '2').to_a).to eq(expected_list)

      # large int should be converted to int
      expected_list = [
        { a: 1, b: 3, c: large_int, name: 'Jane Kelly' }
      ].map(&:with_indifferent_access)
      expect(list.where(c: large_int.to_s).to_a).to eq(expected_list)

      list2 = list.dup
      list2[2] = { a: 1, b: 3, c: large_int.to_s, name: 'Jane Kelly' }.with_indifferent_access
      expected_list = [
        { a: 1, b: 3, c: large_int.to_s, name: 'Jane Kelly' }
      ].map(&:with_indifferent_access)
      expect(list2.where(c: large_int).to_a).to eq(expected_list)

      # large float should be converted to int
      expected_list = [
        { a: 1, b: 3, c: large_float, name: 'Jim Nolan' }
      ].map(&:with_indifferent_access)
      expect(list.where(c: large_float.to_s).to_a).to eq(expected_list)
      list2 = list.dup
      list2[3] = { a: 1, b: 3, c: large_float.to_s, name: 'Jim Nolan' }.with_indifferent_access
      expected_list = [
        { a: 1, b: 3, c: large_float.to_s, name: 'Jim Nolan' }
      ].map(&:with_indifferent_access)
      expect(list2.where(c: large_float).to_a).to eq(expected_list)

      # regexp
      expected_list = [
        { a: 1, b: 2, c: 4, name: 'Kevin N Clark' }
      ].map(&:with_indifferent_access)
      expect(list.where(name: /kevin/i).to_a).to eq(expected_list)

      expected_list = [
        { a: 1, b: 2, c: 3, name: 'Don Martin' },
        { a: 1, b: 2, c: 4, name: 'Kevin N Clark' },
        { a: 2, b: 2, c: 3, name: 'Sofia Miller' }
      ].map(&:with_indifferent_access)
      expect(list.where(name: /(kevin)|(don)|(sofia)/i).to_a).to eq(expected_list)

      # should work with ActiveSupport::HashWithIndifferentAccess objects
      expected_list = [workato_data_list.first]
      expect(workato_data_list.where(email: 'foo@bar.com').to_a).to eq(expected_list)
    end

    it 'returns raise error for nil' do
      # nil handling
      # expect{ list.where("a >=": nil).to_a }.to raise_error(/Can't compare 'a' with nil/)

      list2 = [
        { a: nil, b: 2, c: 3, name: 'Don Martin' }
      ].map(&:with_indifferent_access)

      # expect{ list2.where("a >=": 2).to_a }.to raise_error(/The 'a' is nil/)
      expect { list2.where(a: [2, 3]).to_a }.to raise_error(/Can't compare 'a' with nil/)
      expect { list2.where(a: (2..3)).to_a }.to raise_error(/Can't compare 'a' with nil/)
      expect { list2.where(a: /aaa/).to_a }.to raise_error(/The 'a' is nil/)
    end

    it 'returns valid array for nested hash arrays' do
      list2 = list.map { |r| { b: r }.with_indifferent_access }
      expected_list = [
        { b: { a: 1, b: 2, c: 3, name: 'Don Martin' } },
        { b: { a: 1, b: 2, c: 4, name: 'Kevin N Clark' } },
        { b: { a: 1, b: 3, c: large_int, name: 'Jane Kelly' } },
        { b: { a: 1, b: 3, c: large_float, name: 'Jim Nolan' } }
      ].map(&:with_indifferent_access)
      expect(list2.where('b.a': 1).to_a).to eq(expected_list)

      expected_list = [
        { b: { a: 1, b: 2, c: 3, name: 'Don Martin' } },
        { b: { a: 1, b: 2, c: 4, name: 'Kevin N Clark' } },
        { b: { a: 2, b: 2, c: 3, name: 'Sofia Miller' } }
      ].map(&:with_indifferent_access)

      # symbol
      expect(list2.where('b.b': 2, 'b.c': [3, 4]).to_a).to eq(expected_list)
      # string
      expect(list2.where('b.b' => 2, 'b.c' => [3, 4]).to_a).to eq(expected_list)

      expect(list2.where('b.b': 2, 'b.c': (3..4)).to_a).to eq(expected_list)
      # string
      expect(list2.where('b.b' => 2, 'b.c' => (3..4)).to_a).to eq(expected_list)
    end
  end

  describe 'transform_find' do
    it 'returns the first non null transform' do
      result = [nil, 2, 5, 7].transform_find { |n| n.present? && n == 2 && (n * 2) }
      expect(result).to eq(4)
    end

    it 'returns nil upon no match' do
      result = [nil, 5, 7].transform_find { |n| n.present? && n == 2 && (n * 2) }
      expect(result).to be_nil
    end

    it 'is available in all Enumerables' do
      expect([1, 3, 5, 6, 7, 9].each_with_index.transform_find { |n, i| i * 10 if n.even? })
        .to eq(30)
    end
  end

  describe 'transform_select' do
    it 'returns the non null transforms' do
      result = [nil, 2, 5, 7].transform_select { |n| n.present? && n.odd? && (n * 2) }
      expect(result).to eq([10, 14])
    end

    it 'returns empty array upon no match' do
      result = [2, 4, nil, 8].transform_select { |n| n.present? && n.odd? && (n * 2) }
      expect(result).to eq([])
    end
  end

  describe 'smart_join' do
    it 'ignores nil, empty string, and strings with only spaces and trim the string value' do
      result = [' Hello  ', nil, '', '  ', 'World    '].smart_join(' ')
      expect(result).to eq('Hello World')
    end

    it 'works with non string values' do
      result = ['Hello', 1].smart_join(' ')
      expect(result).to eq('Hello 1')

      float_str = '13.25'
      float = float_str.to_f
      result = ['Hello', float].smart_join(' ')
      expect(result).to eq("Hello #{float_str}")
    end
  end

  describe 'pluck' do
    let :list do
      [
        {
          'name' => 'foo',
          'age' => 23,
          'address' => {
            'city' => 'sunnyvale',
            'state' => 'CA'
          }
        },
        {
          'name' => 'bar',
          'age' => 25,
          'address' => {
            'city' => 'cupertino',
            'state' => 'TX'
          }
        }
      ]
    end

    it 'supports single value pluck' do
      expect(list.pluck('name')).to eq(%w[foo bar])
    end

    it 'supports multi value pluck' do
      expect(list.pluck('name', 'age')).to eq([['foo', 23], ['bar', 25]])
    end

    it 'supports nested single value pluck' do
      expect(list.pluck(%w[address state])).to eq(%w[CA TX])
    end

    it 'supports nested multi value pluck' do
      expect(list.pluck(%w[address city], %w[address state])).to eq([%w[sunnyvale CA], %w[cupertino TX]])
    end
  end
end
