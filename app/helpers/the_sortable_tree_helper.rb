module TheSortableTreeHelper
  # Publicated by MIT
  # Nested Set View Helper
  # Ilya Zykin, zykin-ilya@ya.ru, Russia, Ivanovo 2009-2012
  # github.com/the-teacher
  #-------------------------------------------------------------------------------------------------------

  # = sortable_tree @pages,    :new_url => new_page_url, :max_levels => 5
  # = sortable_tree @products, :new_url => new_product_url, :path => 'products/the_sortable_tree'
  # = sortable_tree @catalogs, :namespace => :admin, :new_url => new_catalog_url, :max_levels => 5

  def define_class_of_elements_of tree
    case
      when tree.is_a?(ActiveRecord::Relation) then tree.name.to_s.underscore.downcase
      when tree.empty? then nil
      else tree.first.class.to_s.underscore.downcase
    end
  end

  def sortable_tree(tree, opts= {})
    opts.merge!({
      :path  => opts[:path] || :the_sortable_tree,
      :klass => define_class_of_elements_of(tree),
      :title => opts[:title] || :title,
      :max_levels => opts[:max_levels] || 3,
      :namespace => Array.wrap(opts[:namespace])
    })
    render :partial => "#{opts[:path]}/tree", :locals => { :tree => sortable_tree_builder(tree, opts), :opts => opts }
  end

  def sortable_tree_builder(tree, options= {})
    result = ''
    opts = {
      :id => :id,           # node id field
      :node => nil,         # node
      :root => false,       # is it root node?
      :level => 0           # recursion level
    }.merge!(options)

    root = opts[:root]
    node = opts[:node]

    unless node
      roots = tree.select{ |elem| elem.parent_id.nil? }

      # TODO: try to remove compact
      # children rendering
      if roots.empty? && !tree.empty?
        min_parent_id = tree.map(&:parent_id).compact.min
        roots = tree.select{ |elem| elem.parent_id == min_parent_id }
      end

      roots.each do |root|
        _opts  =  opts.merge({:node => root, :root => true, :level => opts[:level].next})
        result << sortable_tree_builder(tree, _opts)
      end
    else
      children_res = ''
      children = tree.select{|elem| elem.parent_id == node.id}
      opts.merge!({:has_children => children.blank?})
      children.each do |elem|
        _opts        =  opts.merge({:node => elem, :root => false, :level => opts[:level].next})
        children_res << sortable_tree_builder(tree, _opts)
      end
      result << render(:partial => "#{opts[:path]}/node", :locals => {:opts => opts, :root => root, :node => node, :children => children_res})
    end
    raw result
  end
end
