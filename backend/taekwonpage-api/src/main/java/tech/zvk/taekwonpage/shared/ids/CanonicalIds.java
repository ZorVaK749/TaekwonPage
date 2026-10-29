package tech.zvk.taekwonpage.shared.ids;

import java.util.regex.Pattern;

// One canonical ID rule everywhere: same shape as the PostgreSQL domain canonical_id.
public final class CanonicalIds {
    private static final Pattern CANONICAL = Pattern.compile("[a-z][a-z0-9]*(_[a-z0-9]+)*");

    private CanonicalIds() { }

    public static boolean isValid(String id) {
        return id != null && CANONICAL.matcher(id).matches();
    }

    public static String requireValid(String id) {
        if (!isValid(id)) {
            throw new IllegalArgumentException("Invalid canonical ID");
        }
        return id;
    }
}
