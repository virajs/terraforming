module Terraforming
  module Resource
    class ElastiCacheSubnetGroup
      include Terraforming::Util

      def self.tf(client: Aws::ElastiCache::Client.new)
        self.new(client).tf
      end

      def self.tfstate(client: Aws::ElastiCache::Client.new, tfstate_base: nil)
        self.new(client).tfstate(tfstate_base)
      end

      def initialize(client)
        @client = client
      end

      def tf
        apply_template(@client, "tf/elasti_cache_subnet_group")
      end

      def tfstate(tfstate_base)
        resources = cache_subnet_groups.inject({}) do |result, cache_subnet_group|
          attributes = {
            "description" => cache_subnet_group.cache_subnet_group_description,
            "name" => cache_subnet_group.cache_subnet_group_name,
            "subnet_ids.#" => subnet_ids_of(cache_subnet_group).length.to_s,
          }
          result["aws_elasticache_subnet_group.#{cache_subnet_group.cache_subnet_group_name}"] = {
            "type" => "aws_elasticache_subnet_group",
            "primary" => {
              "id" => cache_subnet_group.cache_subnet_group_name,
              "attributes" => attributes
            }
          }

          result
        end

        generate_tfstate(resources, tfstate_base)
      end

      private

      def cache_subnet_groups
        @client.describe_cache_subnet_groups.cache_subnet_groups
      end

      def subnet_ids_of(cache_subnet_group)
        cache_subnet_group.subnets.map { |sn| sn.subnet_identifier }
      end
    end
  end
end