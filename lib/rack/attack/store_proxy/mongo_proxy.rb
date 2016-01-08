require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class MongoProxy < SimpleDelegator
        def self.handle?(store)
          defined?(::Mongo) && store.is_a?(::Mongo::Client)
        end

        def initialize(store)
          super(store)
        end

        def read(key)
          result = self[:events].find(
            key: key, expires_in: { :$gt => Time.now }
          ).limit(1).first

          result["count"] if result
        end

        def write(key, count, options = {})
          to_insert = { key: key, count: count }

          if options[:expires_in]
            to_insert.merge!(expires_in: Time.now + options[:expires_in])
          end

          self[:events].insert_one(to_insert)
        end

        def increment(key, amount, options = {})
          update_hash = { :$inc => { count: amount } }

          if options[:expires_in]
            update_hash.merge!(
              :$set => { expires_in: Time.now + options[:expires_in] }
            )
          end

          result = self[:events].find_one_and_update(
            { key: key, expires_in: { :$gt => Time.now } },
            update_hash,
            return_document: :after
          )

          result["count"] if result
        end

        def delete(key, options = {})
          self[:events].find(key: key).delete_one
        end
      end
    end
  end
end
