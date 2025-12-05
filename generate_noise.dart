import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final width = 512;
  final height = 512;
  final image = img.Image(width: width, height: height);
  final random = Random();

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final noise = random.nextInt(255);
      image.setPixel(x, y, img.ColorRgb8(noise, noise, noise));
    }
  }

  final png = img.encodePng(image);
  File('assets/film_grain.png').writeAsBytesSync(png);
  stdout.writeln('Generated assets/film_grain.png');
}
