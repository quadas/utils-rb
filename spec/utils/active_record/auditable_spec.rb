require 'spec_helper'

RSpec.describe Utils::AR::Auditable do
  describe 'model without auditable extension' do
    context 'class methods' do
      it '.audit would not responded' do
        expect(Address).not_to respond_to(:audit)
      end

      it '.audit_columns would not responded' do
        expect(Address).not_to respond_to(:audit_columns)
      end
    end

    context 'create new record' do
      before(:context) do
        Activity.delete_all
        @record = Address.create!(street: 'Street', city: 'city', state: 'state', zip: 'zip')
      end

      it 'would not create activity' do
        expect(Activity.count).to eq(0)
      end
    end
  end

  describe 'model with auditable extension' do
    before(:context) do
      Address.include Utils::AR::Auditable
    end

    context 'class methods' do
      it '.audit can be responded' do
        expect(Address).to respond_to(:audit)
      end

      it '.audit_columns can be responded' do
        expect(Address).to respond_to(:audit_columns)
      end
    end

    describe 'audit :all' do
      context 'with exclude options' do
        before(:context) do
          Address.audit all: { exclude: [:zip, :state] }
        end

        it 'excluded fields will not in audit_columns' do
          expect(Address.audit_columns).not_to include(:zip)
          expect(Address.audit_columns).not_to include(:state)
        end

        it 'will not audit excluded fields' do
          current_user = double('current_user', id: 1)
          User = class_double('User', current_user: current_user)
          address = Address.create(street: 'street', city: 'city', state: 'state', zip: 'zip')
          create_activity = address.activities.find_by(action: 'create')
          expect(create_activity.content).not_to include(:zip, :state)

          address.update(street: 'street1', city: 'city1', state: 'state1', zip: 'zip1')
          update_activity = address.activities.where(action: 'update').last
          expect(update_activity.content).not_to include(:zip, :state)
        end
      end

      context 'without exclude options' do
        before(:context) do
          Address.audit :all
        end

        it 'all fields except timestamps include in audit_columns' do
          expect(Address.audit_columns).to include('id', 'street', 'city', 'state', 'zip')
          expect(Address.audit_columns).not_to include('created_at', 'updated_at')
        end

        it 'will audit all fields except timestamps' do
          current_user = double('current_user', id: 1)
          Object.send(:remove_const, :User)
          User = double('User', current_user: current_user)
          address = Address.create(street: 'street', city: 'city', state: 'state', zip: 'zip')
          create_activity = address.activities.find_by(action: 'create')
          expect(create_activity.content).to include('street', 'city', 'state', 'zip')
          expect(create_activity.content).not_to include('created_at', 'updated_at')

          address.update(street: 'street1', city: 'city1', state: 'state1', zip: 'zip1')
          update_activity = address.activities.where(action: 'update').last
          expect(update_activity.content).to include('street', 'city', 'state', 'zip')
          expect(update_activity.content).not_to include('created_at', 'updated_at')
        end
      end
    end

    describe 'audit :field_one, :field_two' do
      before(:context) do
        Address.audit :state, :zip
      end

      it 'just audited fields include in audit_columns' do
        expect(Address.audit_columns).to include('state', 'zip')
      end

      it 'will audit specified fields' do
        current_user = double('current_user', id: 20)
        Object.send(:remove_const, :User)
        User = double('User', current_user: current_user)
        address = Address.create(street: 'street', city: 'city', state: 'state', zip: 'zip')
        create_activity = address.activities.find_by(action: 'create')
        expect(create_activity.operator_id).to eq(20)
        expect(create_activity.content).to include('state', 'zip')
        expect(create_activity.content).not_to include('street', 'city')

        address.update(street: 'street1', city: 'city1', state: 'state1', zip: 'zip1')
        update_activity = address.activities.where(action: 'update').last
        expect(update_activity.operator_id).to eq(20)
        expect(update_activity.content).to include('state', 'zip')
        expect(update_activity.content).not_to include('street', 'city')
      end
    end
  end
end
