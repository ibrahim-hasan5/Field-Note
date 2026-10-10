package com.fieldnotes.security;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class FirebaseUserDetails {
    private final String uid;
    private final String email;
    private final String displayName;
}
