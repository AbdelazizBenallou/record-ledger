import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndSave() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  static Future<String?> takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    return image?.path;
  }
}
