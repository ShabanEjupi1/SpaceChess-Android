# Aplikacioni nuk përdor refleksion askund — nuk ka asnjë varësi që ta kërkonte.
# Rregullat e vetme që duhen janë ato të motorit të Flutter-it, që AGP-ja i shton
# vetë nga `flutter_proguard_rules.pro`.
-dontwarn io.flutter.embedding.**

# Flutter-i referon klasa të Play Core-it që mund të mos jenë fare në paketë
# (komponentët e shtyrë nuk përdoren këtu). Pa këto rreshta R8-a e ndal ndërtimin
# për klasa që nuk do të thirren kurrë.
-dontwarn com.google.android.play.core.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
