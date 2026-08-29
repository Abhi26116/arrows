# Play Core is referenced by Flutter's deferred-components support, which this
# app does not use. Keep R8 from failing on the missing classes.
-dontwarn com.google.android.play.core.**

# Google Mobile Ads and In-App Purchase keep their own consumer rules; nothing
# extra is needed here.
