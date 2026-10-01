# ML Kit text recognition (receipt scanning) ships recognizers for several
# scripts as optional modules. The Flutter plugin references them all, but only
# the Latin one is bundled, so R8 must not fail on the missing ones.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
