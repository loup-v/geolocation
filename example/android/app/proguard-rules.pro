# Geolocation - start

-keep class app.loup.geolocation.** { *; }

    # Moshi - start
    # https://github.com/square/moshi/blob/master/moshi/src/main/resources/META-INF/proguard/moshi.pro

    # JSR 305 annotations are for embedding nullability information.
    -dontwarn javax.annotation.**

    -keepclasseswithmembers class * {
        @com.squareup.moshi.* <methods>;
    }

    -keep @com.squareup.moshi.JsonQualifier interface *

    # Enum field names are used by the integrated EnumJsonAdapter.
    # values() is synthesized by the Kotlin compiler and is used by EnumJsonAdapter indirectly
    # Annotate enums with @JsonClass(generateAdapter = false) to use them with Moshi.
    -keepclassmembers @com.squareup.moshi.JsonClass class * extends java.lang.Enum {
        <fields>;
        **[] values();
    }

    # Moshi - end

# Geolocation - end



