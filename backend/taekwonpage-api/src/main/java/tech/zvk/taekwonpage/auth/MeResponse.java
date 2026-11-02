package tech.zvk.taekwonpage.auth;

import java.util.List;

// Identity echo only: id, username and roles. No email, no grade, no content.
public record MeResponse(String id, String username, List<String> roles) {
}
