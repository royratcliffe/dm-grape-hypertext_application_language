require 'data_mapper'
require 'hypertext_application_language'

module DataMapper
  module Serializer
    # Converts a Data Mapper resource to a hypertext application language (HAL)
    # representation.
    #
    # The resulting representation contains links for each relationship. There
    # are two main kinds of Data Mapper relationships: to-one and to-many. For
    # to-many relationships, the links contain a reference to a sub-path for
    # accessing or creating sub-resources based on the name of the
    # relationship. If the relationship is to-one, then the link depends on
    # whether or not the to-one association exists. If it does already exist,
    # then the link references a root-level hypertext path to the resource by
    # its relationship name and its unique identifier; assuming that path
    # +relationship/identifier+ resolves to the existing resources
    # representation.
    def to_hal(*args)
      representation = HypertextApplicationLanguage::Representation.new

      rel = model.to_s.tableize
      representation.with_link(HypertextApplicationLanguage::Link::SELF_REL, "#{rel}/#{id}")

      model.relationships.each do |relationship|
        association = __send__(relationship.name)
        href = if association == nil || association.is_a?(DataMapper::Collection)
                 "#{representation.link.href}/#{relationship.name}"
               else
                 "#{association.model.to_s.tableize}/#{association.id}"
               end
        representation.with_link(relationship.name, href)
      end

      exclude = model.properties(repository.name).map(&:name).select do |name|
        name.to_s.end_with?('_id')
      end + %i(id)

      properties_to_serialize(exclude: exclude).map(&:name).each do |name|
        value = __send__(name)
        representation.with_property(name, value)
      end

      representation
    end
  end

  class Collection
    # Converts a collection to HAL. Represents a collection by constructing a
    # set of embedded representations associated with a relation. The name of
    # the relation is the table name of the collection's underlying model. The
    # collection representation includes other useful pieces of information: the
    # offset, limit and chunk size, useful for paging.
    #
    # Sends +each+ to the collection to access the individual
    # resources. Converts each one to HAL then embeds the results within the
    # resulting collection representation. The resulting collection
    # representation both embeds the resources and includes links to the same
    # resources.
    #
    # Only adds a link to self if the arguments include a Rack environment and
    # the rack environment specifies the request path. This assumes that the
    # request path is either an absolute path because it begins with a slash, or
    # a relative path because higher-level Rack formatters will make the
    # reference absolute by adding the base URL and script name.
    #
    # @return [HypertextApplicationLanguage::Representation]
    #   Representation of a collection of resources.
    def to_hal(*args)
      keyword_args = args.last.is_a?(Hash) ? args.pop : {}
      representation = HypertextApplicationLanguage::Representation.new

      if (env = keyword_args[:env]) && (href = env['REQUEST_PATH'])
        representation.with_link(HypertextApplicationLanguage::Link::SELF_REL, href)
      end

      rel = model.to_s.tableize

      each do |resource|
        resource_representation = resource.to_hal(*args)
        representation.with_link(rel, resource_representation.link.href)
        representation.with_representation(rel, resource_representation)
      end

      %w(size).each do |name|
        representation.with_property(name, __send__(name))
      end
      %w(offset limit).each do |name|
        representation.with_property(name, query.__send__(name))
      end

      representation
    end
  end
end
