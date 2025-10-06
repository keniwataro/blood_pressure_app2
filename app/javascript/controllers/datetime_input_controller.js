import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 初期値の秒を0に設定
    this.formatDateTime()
  }

  formatDateTime() {
    if (this.element.value) {
      // 現在の値をDateオブジェクトに変換
      const currentValue = new Date(this.element.value)
      
      // 秒とミリ秒を0に設定
      currentValue.setSeconds(0, 0)
      
      // yyyy-MM-ddThh:mm 形式に変換して設定
      const year = currentValue.getFullYear()
      const month = String(currentValue.getMonth() + 1).padStart(2, '0')
      const day = String(currentValue.getDate()).padStart(2, '0')
      const hours = String(currentValue.getHours()).padStart(2, '0')
      const minutes = String(currentValue.getMinutes()).padStart(2, '0')
      
      const formattedValue = `${year}-${month}-${day}T${hours}:${minutes}`
      
      // 値が変更された場合のみ更新（無限ループ防止）
      if (this.element.value !== formattedValue) {
        this.element.value = formattedValue
      }
    }
  }
}
