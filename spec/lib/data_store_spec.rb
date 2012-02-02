require_relative '../../lib/hashy_db/data_store'

describe HashyDB::DataStore do
  subject { HashyDB::DataStore.instance }

  let(:data1) { { id: 1, field_1: 'value 1', field_2: 3, field_3: [1,2,3], shared_between_1_and_2: 'awesome_value', :some_array => [1,2,3,4] } }
  let(:data2) { { id: 2, field_1: 'value 1.2', field_2: 6, shared_between_1_and_2: 'awesome_value', :some_array => [4,5,6] } }
  let(:data3) { { id: 3, field_1: 'value 3', field_2: 9, shared_between_1_and_2: 'not the same as 1 and 2', :some_array => [1,7] } }

  before do
    subject.data_store = {}
    subject.insert(:some_collection, [data1, data2, data3])
  end

  it 'can write and read data to and from a collection' do
    data4 = { id: 3, field_1: 'value 3', field_2: 9, shared_between_1_and_2: 'not the same as 1 and 2', :some_array => [1,7] }

    subject.add(:some_collection, data4)
    subject.get(:some_collection).should == [data1, data2, data3, data4]
  end

  it 'can replace a record' do
    data2[:field_1] = 'value modified'
    subject.replace(:some_collection, data2)

    subject.get_one(:some_collection, :id, 2)[:field_1].should == 'value modified'
  end

  it 'can get one document' do
    subject.get_one(:some_collection, :field_1, 'value 1').should == data1
    subject.get_one(:some_collection, :field_2, 6).should == data2
  end

  it 'can clear the data store' do
    subject.clear

    subject.get(:some_collection).should == []
  end

  it 'can get all records of a specific key value' do
    subject.get_all_for_key_with_value(:some_collection, :shared_between_1_and_2, 'awesome_value').should == [data1, data2]
  end

  it 'can get all records where a value includes any of a set of values' do
    subject.containing_any(:some_collection, :some_array, []).should == []
    subject.containing_any(:some_collection, :some_array, [7, 2, 3]).should == [data1, data3]
    subject.containing_any(:some_collection, :id, [1, 2, 5]).should == [data1, data2]
  end
  
  it 'can get all records where the array includes a value' do
    subject.array_contains(:some_collection, :some_array, 1).should == [data1, data3]
    subject.array_contains(:some_collection, :some_array_2, 1).should == []
  end

  it 'can push a value to an array for a specific record' do
    subject.push_to_array(:some_collection, :id, 1, :field_3, 'add to existing array')
    subject.push_to_array(:some_collection, :id, 1, :new_field, 'add to new array')

    subject.get_one(:some_collection, :id, 1)[:field_3].should include('add to existing array')
    subject.get_one(:some_collection, :id, 1)[:new_field].should == ['add to new array']
  end

  it 'can remove a value from an array for a specific record' do
    subject.remove_from_array(:some_collection, :id, 1, :field_3, 2)

    subject.get_one(:some_collection, :id, 1)[:field_3].should_not include(2)
  end

  it 'can get all records that match a given set of keys and values' do
    records = subject.get_by_params(:some_collection, field_1: 'value 1', shared_between_1_and_2: 'awesome_value')
    records.size.should be(1)
    records.first[:id].should == 1
    subject.get(:some_collection).size.should == 3
  end

  it 'can get a record for a specific key and value' do
    subject.get_for_key_with_value(:some_collection, :field_1, 'value 1').should == data1
  end
end
