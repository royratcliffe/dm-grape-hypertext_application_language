require 'grape'
require 'data_mapper'
require 'active_support/core_ext/hash'

module HypertextApplicationLanguage
  module DataMapper
    module Grape
      class API < ::Grape::API
        route_param :model do
          helpers do
            # Takes the model name from the route path. Takes a string and
            # answers a string, but the result is upper camel-case and singular.
            # @return [String] Answers the name of the model based on the route
            # parameter.
            def model_name
              params[:model].classify
            end

            def model
              ::DataMapper::Model.descendants.select do |model|
                model.name == model_name
              end.first
            end

            # @return [Array<Symbol>] Answers the names of the model properties.
            def property_names(model=model)
              model.properties.map(&:name)
            end

            def attribute_names(property_names=property_names)
              property_names.map(&:to_s).select do |name|
                !name.end_with?('_id')
              end - %w(id)
            end

            def attributes
              params.slice(*attribute_names)
            end

            # The order parameter is an array of Data Mapper query
            # directions. Each direction specifies a target property and a
            # vector, ascending or descending, space delimited (or plus
            # delimited after URL encoding). However, Grape cannot coerce the
            # directions because directions need access to the model properties
            # in order to construct the direction. The model comes from the
            # helpers who only become available after parameter coercion and
            # validation of parameters. Note that Grape _does_ coerce the order
            # to an array even if the parameters do not specify an array.
            def query(model=model)
              query = declared(params, include_missing: true)
              if query.order
                query.order.map! do |direction|
                  target, operator = direction.split(' ', 2)
                  property = model.properties[target]
                  error! "no property named #{target}" unless property
                  ::DataMapper::Query::Direction.new(property, operator || 'asc')
                end
              end
              query.to_h.symbolize_keys
            end
          end

          params do
            optional :offset, type: Integer, default: 0
            optional :limit, type: Integer, default: 30
            optional :order, type: [String]
          end
          get do
            model.all(query)
          end

          post do
            resource = model.create(attributes)
            error! resource.errors.full_messages unless resource.save
            resource
          end

          route_param :id do
            helpers do
              def resource
                model.get(params[:id])
              end
            end

            get do
              resource
            end

            patch do
              resource = self.resource
              resource.update(attributes)
              error! resource.errors.full_messages unless resource.save
              resource
            end

            delete do
              resource = self.resource
              error! unless resource.destroy
            end

            route_param :relationship do
              helpers do
                def relationship_name
                  params[:relationship]
                end

                def relationship
                  resource.model.relationships.select do |relationship|
                    relationship.name.to_s == relationship_name
                  end.first
                end

                def target_model
                  relationship.target_model
                end

                def target_property_names
                  property_names(target_model)
                end

                def target_attribute_names
                  attribute_names(target_property_names)
                end

                def target_attributes
                  params.slice(*target_attribute_names)
                end

                def association
                  resource.__send__(relationship_name)
                end

                def association=(target)
                  resource.__send__("#{relationship_name}=", target)
                end
              end

              params do
                optional :offset, type: Integer, default: 0
                optional :limit, type: Integer, default: 30
                optional :order, type: [String]
              end
              get do
                association.all(query(target_model))
              end

              post do
                target = target_model.create(target_attributes)
                if association.is_a?(::DataMapper::Collection)
                  association << target
                else
                  self.assocation = target
                end
                error! target.errors.full_messages unless target.save
                target
              end
            end
          end
        end
      end
    end
  end
end
