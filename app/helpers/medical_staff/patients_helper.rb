module MedicalStaff::PatientsHelper
  # 患者管理に関するヘルパーメソッド
  def patient_status_badge(patient)
    if patient.current_role&.name&.start_with?("患者")
      content_tag(:span, "患者", class: "badge badge-primary")
    else
      content_tag(:span, "未設定", class: "badge badge-secondary")
    end
  end

  def patient_action_links(patient)
    content_tag(:div, class: "btn-group") do
      concat link_to("詳細", medical_staff_patient_path(patient), class: "btn btn-sm btn-outline-primary")
      concat link_to("編集", edit_medical_staff_patient_path(patient), class: "btn btn-sm btn-outline-secondary")
    end
  end
end
