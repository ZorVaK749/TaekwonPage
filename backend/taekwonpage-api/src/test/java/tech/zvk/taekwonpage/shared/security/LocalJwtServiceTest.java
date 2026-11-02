package tech.zvk.taekwonpage.shared.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.Set;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.junit.jupiter.api.Test;

class LocalJwtServiceTest {
    private static final String SECRET = "unit-test-secret-with-more-than-thirty-two-bytes!";
    private static final String ISSUER = "taekwonpage-test";
    private static final Instant NOW = Instant.parse("2026-11-02T12:00:00Z");
    private static final AuthenticatedUser USER =
        new AuthenticatedUser("user_alice", "alice", Set.of("ROLE_STUDENT"));
    private static final Base64.Encoder ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder DECODER = Base64.getUrlDecoder();

    private static LocalJwtService service(Instant now) {
        return new LocalJwtService(SECRET, ISSUER, Duration.ofSeconds(60), Clock.fixed(now, ZoneOffset.UTC));
    }

    private static String sign(String signingInput) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        return ENCODER.encodeToString(mac.doFinal(signingInput.getBytes(StandardCharsets.UTF_8)));
    }

    @Test
    void issuedTokenRoundTripsTheIdentity() {
        String token = service(NOW).issue(USER);
        assertThat(token.split("\\.")).hasSize(3);
        var claims = service(NOW).parse(token);
        assertThat(claims.id()).isEqualTo("user_alice");
        assertThat(claims.username()).isEqualTo("alice");
        assertThat(claims.roles()).containsExactly("ROLE_STUDENT");
    }

    @Test
    void weakSecretsAreRejectedAtConstruction() {
        assertThatThrownBy(() -> new LocalJwtService("short", ISSUER, Duration.ofSeconds(60)))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new LocalJwtService(null, ISSUER, Duration.ofSeconds(60)))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new LocalJwtService(SECRET, " ", Duration.ofSeconds(60)))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new LocalJwtService(SECRET, ISSUER, Duration.ZERO))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void tokenFromAnotherIssuerOrSecretIsRejected() {
        String token = service(NOW).issue(USER);
        var otherIssuer = new LocalJwtService(SECRET, "someone-else", Duration.ofSeconds(60),
            Clock.fixed(NOW, ZoneOffset.UTC));
        assertThatThrownBy(() -> otherIssuer.parse(token)).isInstanceOf(InvalidJwtException.class);

        var otherSecret = new LocalJwtService("another-secret-with-more-than-thirty-two-bytes!!",
            ISSUER, Duration.ofSeconds(60), Clock.fixed(NOW, ZoneOffset.UTC));
        assertThatThrownBy(() -> otherSecret.parse(token)).isInstanceOf(InvalidJwtException.class);
    }

    @Test
    void tamperedSignatureOrPayloadIsRejected() throws Exception {
        String token = service(NOW).issue(USER);
        String[] parts = token.split("\\.");

        char[] signature = parts[2].toCharArray();
        signature[10] = signature[10] == 'A' ? 'B' : 'A';
        assertThatThrownBy(() -> service(NOW).parse(parts[0] + "." + parts[1] + "." + new String(signature)))
            .isInstanceOf(InvalidJwtException.class);

        String payload = new String(DECODER.decode(parts[1]), StandardCharsets.UTF_8);
        String forged = ENCODER.encodeToString(
            payload.replace("alice", "admin").getBytes(StandardCharsets.UTF_8));
        assertThatThrownBy(() -> service(NOW).parse(parts[0] + "." + forged + "." + parts[2]))
            .isInstanceOf(InvalidJwtException.class);
    }

    @Test
    void unsignedAndNonHs256TokensAreRejected() throws Exception {
        String payload = ENCODER.encodeToString(
            ("{\"sub\":\"user_alice\",\"username\":\"alice\",\"roles\":[\"ROLE_ADMIN\"],"
                + "\"iat\":" + NOW.getEpochSecond() + ",\"exp\":" + NOW.plusSeconds(60).getEpochSecond()
                + ",\"iss\":\"" + ISSUER + "\"}").getBytes(StandardCharsets.UTF_8));
        String noneHeader = ENCODER.encodeToString("{\"alg\":\"none\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8));
        assertThatThrownBy(() -> service(NOW).parse(noneHeader + "." + payload + ".AA"))
            .isInstanceOf(InvalidJwtException.class);

        String hs512Header = ENCODER.encodeToString("{\"alg\":\"HS512\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8));
        String forged = hs512Header + "." + payload + "." + sign(hs512Header + "." + payload);
        assertThatThrownBy(() -> service(NOW).parse(forged)).isInstanceOf(InvalidJwtException.class);
    }

    @Test
    void expiredAndFutureTokensAreRejected() {
        String expired = service(NOW).issue(USER, NOW.minusSeconds(120));
        assertThatThrownBy(() -> service(NOW).parse(expired)).isInstanceOf(InvalidJwtException.class);

        String future = service(NOW).issue(USER, NOW.plusSeconds(300));
        assertThatThrownBy(() -> service(NOW).parse(future)).isInstanceOf(InvalidJwtException.class);
    }

    @Test
    void malformedTokensAreRejectedWithoutDifferentErrorsReachingCallers() {
        var parser = service(NOW);
        for (String token : new String[] {null, "", "onepart", "a.b", "..", "a..c", "not-base64!!.x.y"}) {
            assertThatThrownBy(() -> parser.parse(token)).isInstanceOf(InvalidJwtException.class);
        }
    }

    @Test
    void unparseableRoleClaimsAreRejected() throws Exception {
        String header = ENCODER.encodeToString("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8));
        String payload = ENCODER.encodeToString(
            ("{\"sub\":\"user_alice\",\"username\":\"alice\",\"roles\":[\"ADMIN\"],"
                + "\"iat\":" + NOW.getEpochSecond() + ",\"exp\":" + NOW.plusSeconds(60).getEpochSecond()
                + ",\"iss\":\"" + ISSUER + "\"}").getBytes(StandardCharsets.UTF_8));
        String token = header + "." + payload + "." + sign(header + "." + payload);
        assertThatThrownBy(() -> service(NOW).parse(token)).isInstanceOf(InvalidJwtException.class);
    }

    private static String signedJson(String header, String payload) throws Exception {
        String input = ENCODER.encodeToString(header.getBytes(StandardCharsets.UTF_8)) + "."
            + ENCODER.encodeToString(payload.getBytes(StandardCharsets.UTF_8));
        return input + "." + sign(input);
    }

    @Test
    void signedClaimsMustHaveStrictTypesKnownRolesAndCompleteLifetime() throws Exception {
        var mapper = new ObjectMapper();
        String original = new String(DECODER.decode(service(NOW).issue(USER).split("\\.")[1]), StandardCharsets.UTF_8);
        for (String mutation : new String[] {"missing-iat", "string-exp", "fractional-iat", "unknown-role",
                "duplicate-role", "numeric-sub", "bad-username", "excess-ttl", "nbf"}) {
            ObjectNode payload = (ObjectNode) mapper.readTree(original);
            switch (mutation) {
                case "missing-iat" -> payload.remove("iat");
                case "string-exp" -> payload.put("exp", Long.toString(NOW.plusSeconds(60).getEpochSecond()));
                case "fractional-iat" -> payload.put("iat", NOW.getEpochSecond() + 0.5);
                case "unknown-role" -> payload.putArray("roles").add("ROLE_SUPERUSER");
                case "duplicate-role" -> payload.putArray("roles").add("ROLE_ADMIN").add("ROLE_ADMIN");
                case "numeric-sub" -> payload.put("sub", 123);
                case "bad-username" -> payload.put("username", "bad name!");
                case "excess-ttl" -> payload.put("exp", NOW.plusSeconds(61).getEpochSecond());
                case "nbf" -> payload.put("nbf", NOW.plusSeconds(30).getEpochSecond());
                default -> throw new AssertionError(mutation);
            }
            String token = signedJson("{\"alg\":\"HS256\",\"typ\":\"JWT\"}", payload.toString());
            assertThatThrownBy(() -> service(NOW).parse(token)).as(mutation).isInstanceOf(InvalidJwtException.class);
        }
    }

    @Test
    void duplicateJsonKeysTrailingJsonAndUnsupportedHeadersAreRejected() throws Exception {
        String payload = new String(DECODER.decode(service(NOW).issue(USER).split("\\.")[1]), StandardCharsets.UTF_8);
        for (String header : new String[] {
                "{\"alg\":\"HS512\",\"alg\":\"HS256\",\"typ\":\"JWT\"}",
                "{\"alg\":\"HS256\",\"typ\":\"JWT\",\"crit\":[\"custom\"]}",
                "{\"alg\":\"HS256\",\"typ\":\"JWT\"} {}"}) {
            String token = signedJson(header, payload);
            assertThatThrownBy(() -> service(NOW).parse(token)).isInstanceOf(InvalidJwtException.class);
        }
        String duplicate = signedJson("{\"alg\":\"HS256\",\"typ\":\"JWT\"}",
            "{\"sub\":\"user_other\"," + payload.substring(1));
        assertThatThrownBy(() -> service(NOW).parse(duplicate)).isInstanceOf(InvalidJwtException.class);
    }

    @Test
    void boundsExpiryAndNoncanonicalInputAreRejected() {
        assertThatThrownBy(() -> service(NOW).parse("x".repeat(8193))).isInstanceOf(InvalidJwtException.class);
        assertThatThrownBy(() -> new LocalJwtService(SECRET, ISSUER, Duration.ofMillis(500)))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service(NOW).issue(new AuthenticatedUser("Bad_Id", "alice", Set.of("ROLE_ADMIN"))))
            .isInstanceOf(IllegalArgumentException.class);
        String token = service(NOW).issue(USER);
        assertThat(service(NOW.plusSeconds(59)).parse(token).id()).isEqualTo(USER.id());
        assertThatThrownBy(() -> service(NOW.plusSeconds(60)).parse(token)).isInstanceOf(InvalidJwtException.class);
        assertThatThrownBy(() -> service(NOW).parse(token + "=")).isInstanceOf(InvalidJwtException.class);
    }
}
