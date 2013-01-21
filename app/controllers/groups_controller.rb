class GroupsController < CrudController

  decorates :group, :groups, :contact
  
  before_render_show :load_sub_groups
  before_render_form :load_contacts


  def index
    flash.keep
    redirect_to group_path(Group.root.id)
  end

  def destroy
    super(location: entry.parent)
  end

  def deleted_subgroups
    load_sub_groups(entry.children.only_deleted)
  end

  def reactivate
    entry.update_column(:deleted_at, nil)

    flash[:notice] = "Gruppe <i>#{entry}</i> wurde erfolgreich reaktiviert."
    redirect_to entry
  end


  private
  
  def build_entry
    type = model_params && model_params.delete(:type)
    group = Group.find_group_type!(type).new
    group.parent_id = model_params.delete(:parent_id)
    group
  end

  def assign_attributes
    role = entry.class.superior_attributes.present? && can?(:modify_superior, entry) ? :superior : :default
    entry.assign_attributes(model_params, as: role)
  end

  def load_contacts
    @contacts = entry.people.affiliate(false).only_public_data.order_by_name
  end
  
  def load_sub_groups(scope = entry.children.without_deleted)
    @sub_groups = Hash.new {|h, k| h[k] = [] }
    scope.order_by_type(entry).each do |group|
      label = group.layer ? group.class.label_plural : 'Untergruppen'
      @sub_groups[label] << group
    end
    # move this entry to the end
    @sub_groups['Untergruppen'] = @sub_groups.delete('Untergruppen')
  end



end
