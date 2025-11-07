module MedicalStaff::StaffHelper
  # スタッフ管理に関するヘルパーメソッド
  def staff_role_badge(staff)
    role = staff.current_role
    if role&.is_medical_staff?
      content_tag(:span, role.name, class: "badge badge-success")
    else
      content_tag(:span, "医療従事者以外", class: "badge badge-warning")
    end
  end

  def staff_permission_badge(staff)
    hospital_role = staff.user_hospital_roles.find_by(hospital_id: current_user.hospitals_as_staff.first&.id)
    if hospital_role&.permission_level_administrator?
      content_tag(:span, "管理者", class: "badge badge-danger")
    elsif hospital_role&.permission_level_general?
      content_tag(:span, "一般", class: "badge badge-info")
    else
      content_tag(:span, "未設定", class: "badge badge-secondary")
    end
  end

  def staff_action_links(staff)
    content_tag(:div, class: "btn-group") do
      concat link_to("詳細", medical_staff_staff_path(staff), class: "btn btn-sm btn-outline-primary")
      concat link_to("編集", edit_medical_staff_staff_path(staff), class: "btn btn-sm btn-outline-secondary")
    end
  end
end
