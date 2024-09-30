# frozen_string_literal: true

class ResqueAPIStub
  def self.create(class_name, queue)
    if Object.const_defined?(class_name)
      klass = Kernel.const_get(class_name)
      klass.instance_variable_set(:@queue, queue)
      klass
    else
      object_strings = class_name.split('::')
      class_string = object_strings.pop
      if object_strings.empty?
        create_class(class_string, queue)
      else
        parent_module = nil
        object_strings.each do |module_name|
          parent_module = create_module(module_name, parent_module)
        end
        create_class(class_string, queue, parent_module)
      end
    end
  end

  def self.create_class(class_name, queue, parent_module = nil)
    parent_module ||= Object
    parent_module.const_set(class_name, Class.new do
      @queue = queue
      def self.perform
      end
    end)
  end

  def self.create_module(current_module, parent_module)
    parent_module ||= Object
    parent_module.const_get(current_module)
  rescue StandardError
    parent_module.const_set(current_module, Module.new)
  end
end
