package tech.zvk.taekwonpage.shared.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashSet;
import java.util.Set;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

// C1: JWT local autoemitido. HS256 with the JDK only (no new dependency), one
// signing secret from the environment, fixed short TTL and no refresh token.
// The token identifies the user; it never grants content access by itself.
public class LocalJwtService {
    private static final String ALGORITHM = "HmacSHA256";
    private static final String EXPECTED_ALG = "HS256";
    private static final String EXPECTED_TYP = "JWT";
    private static final Base64.Encoder ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder DECODER = Base64.getUrlDecoder();
    private static final ObjectMapper JSON = new ObjectMapper()
        .enable(JsonParser.Feature.STRICT_DUPLICATE_DETECTION)
        .enable(DeserializationFeature.FAIL_ON_TRAILING_TOKENS);
    private static final Set<String> ROLES = Set.of("ROLE_GUEST", "ROLE_STUDENT", "ROLE_ADMIN", "ROLE_DEVELOPER");

    private final byte[] secret;
    private final String issuer;
    private final Duration ttl;
    private final Clock clock;

    public LocalJwtService(String secret, String issuer, Duration ttl) {
        this(secret, issuer, ttl, Clock.systemUTC());
    }

    public LocalJwtService(String secret, String issuer, Duration ttl, Clock clock) {
        if (secret == null || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalArgumentException("JWT secret must be at least 32 bytes");
        }
        if (issuer == null || issuer.isBlank()) {
            throw new IllegalArgumentException("JWT issuer is required");
        }
        if (ttl == null || ttl.getSeconds() < 1 || ttl.getNano() != 0) {
            throw new IllegalArgumentException("JWT ttl must be a positive whole number of seconds");
        }
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
        this.issuer = issuer;
        this.ttl = ttl;
        this.clock = clock;
    }

    public long ttlSeconds() {
        return ttl.getSeconds();
    }

    public String issue(AuthenticatedUser user) {
        return issue(user, Instant.now(clock));
    }

    // issuedAt is visible for deterministic tests only; callers in production
    // use issue(user).
    public String issue(AuthenticatedUser user, Instant issuedAt) {
        if (user == null || !CanonicalIds.isValid(user.id())
                || user.username() == null || !user.username().matches("[A-Za-z0-9._-]{3,64}")
                || !ROLES.containsAll(user.roles())) {
            throw new IllegalArgumentException("cannot issue a token without a complete identity");
        }
        ObjectNode header = JSON.createObjectNode();
        header.put("alg", EXPECTED_ALG);
        header.put("typ", EXPECTED_TYP);
        ObjectNode payload = JSON.createObjectNode();
        payload.put("sub", user.id());
        payload.put("username", user.username());
        ArrayNode roles = payload.putArray("roles");
        user.roles().stream().sorted().forEach(roles::add);
        payload.put("iat", issuedAt.getEpochSecond());
        payload.put("exp", issuedAt.plus(ttl).getEpochSecond());
        payload.put("iss", issuer);
        String signingInput = encode(header) + "." + encode(payload);
        return signingInput + "." + encode(hmac(signingInput));
    }

    public JwtClaims parse(String token) {
        if (token == null || token.isBlank() || token.length() > 8192) {
            throw new InvalidJwtException("empty token");
        }
        String[] parts = token.split("\\.", -1);
        if (parts.length != 3 || parts[0].isEmpty() || parts[1].isEmpty() || parts[2].isEmpty()) {
            throw new InvalidJwtException("malformed token");
        }
        JsonNode header = readJson(parts[0], "header");
        if (!EXPECTED_ALG.equals(header.path("alg").asText())
                || !EXPECTED_TYP.equals(header.path("typ").asText()) || header.size() != 2) {
            throw new InvalidJwtException("unsupported token header");
        }
        byte[] expected = hmac(parts[0] + "." + parts[1]);
        byte[] provided;
        try {
            provided = DECODER.decode(parts[2]);
            if (provided.length != 32 || !ENCODER.encodeToString(provided).equals(parts[2])) {
                throw new InvalidJwtException("noncanonical signature");
            }
        } catch (IllegalArgumentException invalidBase64) {
            throw new InvalidJwtException("malformed signature");
        }
        if (!MessageDigest.isEqual(expected, provided)) {
            throw new InvalidJwtException("bad signature");
        }
        JsonNode payload = readJson(parts[1], "payload");
        if (!payload.path("iss").isTextual() || !issuer.equals(payload.path("iss").asText())) {
            throw new InvalidJwtException("unexpected issuer");
        }
        Instant now = Instant.now(clock);
        JsonNode exp = payload.path("exp");
        JsonNode iat = payload.path("iat");
        if (!exp.isIntegralNumber() || !exp.canConvertToLong()
                || !iat.isIntegralNumber() || !iat.canConvertToLong()
                || iat.longValue() < 0 || iat.longValue() > now.getEpochSecond()
                || exp.longValue() <= now.getEpochSecond() || exp.longValue() <= iat.longValue()
                || exp.longValue() - iat.longValue() > ttlSeconds()
                || payload.has("nbf")) {
            throw new InvalidJwtException("invalid token lifetime");
        }
        String id = payload.path("sub").asText("");
        String username = payload.path("username").asText("");
        if (!payload.path("sub").isTextual() || !CanonicalIds.isValid(id)
                || !payload.path("username").isTextual() || !username.matches("[A-Za-z0-9._-]{3,64}")
                || !payload.path("roles").isArray()) {
            throw new InvalidJwtException("incomplete identity claims");
        }
        var roles = new LinkedHashSet<String>();
        for (JsonNode role : payload.get("roles")) {
            if (!role.isTextual() || !ROLES.contains(role.textValue()) || roles.contains(role.textValue())) {
                throw new InvalidJwtException("unexpected role claim");
            }
            roles.add(role.asText());
        }
        return new JwtClaims(id, username, roles);
    }

    private JsonNode readJson(String encoded, String part) {
        try {
            byte[] decoded = DECODER.decode(encoded);
            if (!ENCODER.encodeToString(decoded).equals(encoded)) {
                throw new InvalidJwtException("noncanonical " + part);
            }
            JsonNode node = JSON.readTree(decoded);
            if (node == null || !node.isObject()) {
                throw new InvalidJwtException("malformed " + part);
            }
            return node;
        } catch (InvalidJwtException rejected) {
            throw rejected;
        } catch (Exception malformed) {
            throw new InvalidJwtException("malformed " + part);
        }
    }

    private String encode(JsonNode node) {
        return ENCODER.encodeToString(node.toString().getBytes(StandardCharsets.UTF_8));
    }

    private String encode(byte[] bytes) {
        return ENCODER.encodeToString(bytes);
    }

    private byte[] hmac(String signingInput) {
        try {
            Mac mac = Mac.getInstance(ALGORITHM);
            mac.init(new SecretKeySpec(secret, ALGORITHM));
            return mac.doFinal(signingInput.getBytes(StandardCharsets.UTF_8));
        } catch (GeneralSecurityException unavailable) {
            throw new IllegalStateException("HMAC-SHA256 unavailable", unavailable);
        }
    }
}
