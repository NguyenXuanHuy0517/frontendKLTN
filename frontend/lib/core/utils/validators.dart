class Validators {
  static String? required(String? value, {String? label}) {
    if (value == null || value.trim().isEmpty) {
      return '${label ?? 'Trường này'} không được để trống';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email không được để trống';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Email không hợp lệ';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số điện thoại không được để trống';
    }
    final regex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');
    if (!regex.hasMatch(value)) return 'Số điện thoại không hợp lệ';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Mật khẩu không được để trống';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  static String? number(String? value, {String? label}) {
    if (value == null || value.isEmpty) {
      return '${label ?? 'Giá trị'} không được để trống';
    }
    if (double.tryParse(value) == null) {
      return '${label ?? 'Giá trị'} phải là số';
    }
    return null;
  }
}