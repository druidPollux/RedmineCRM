class Part < ActiveRecord::Base
  unloadable

  has_and_belongs_to_many :pages, :uniq => true

  acts_as_attachable

  default_scope order(:part_type)

  scope :global, where(:is_global => true)

  liquid_methods :name, :attachments, :title

  after_commit :touch_pages

  validates_uniqueness_of :name
  validates_presence_of :name, :part_type, :content_type
  validates_format_of :name, :with => /^(?!\d+$)[a-z0-9\-_]*$/

 [:content, :header, :footer, :sidebar].each do |name, params|
    src = <<-END_SRC
    def is_#{name}_type?
      self.part_type.strip.downcase == "#{name.to_s}"
    end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end

  def copy_from(arg)
    part = arg.is_a?(Part) ? arg : Part.find_by_id(arg)
    self.attributes = part.attributes.dup.except("id", "name", "created_at", "updated_at") if part
    self
  end


private
  def touch_pages
    pages.each{|p| p.touch} if pages
  end

end
