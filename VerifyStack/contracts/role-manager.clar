;; Role Management Contract
;; Handles role-based access control for identity verification

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ROLE_ADMIN u1)
(define-constant ROLE_VERIFIER u2)
(define-constant ROLE_AUDITOR u3)

;; Permission types
(define-constant PERM_REGISTER u1)
(define-constant PERM_VERIFY u2)
(define-constant PERM_AUDIT u3)
(define-constant PERM_ASSIGN u4)

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_ROLE_EXISTS (err u301))
(define-constant ERR_NO_ROLE (err u302))
(define-constant ERR_INVALID_ROLE (err u303))

;; Data Maps
(define-map UserRoles
    { user: principal }
    { 
        role: uint,
        assigned-by: principal,
        assigned-at: uint,
        active: bool
    }
)

(define-map RolePermissions
    { role: uint }
    {
        register: bool,
        verify: bool,
        audit: bool,
        assign: bool
    }
)

;; Initialize default role permissions
(map-set RolePermissions
    { role: ROLE_ADMIN }
    {
        register: true,
        verify: true,
        audit: true,
        assign: true
    }
)

(map-set RolePermissions
    { role: ROLE_VERIFIER }
    {
        register: false,
        verify: true,
        audit: false,
        assign: false
    }
)

(map-set RolePermissions
    { role: ROLE_AUDITOR }
    {
        register: false,
        verify: false,
        audit: true,
        assign: false
    }
)

;; Public functions
(define-public (assign-role (user principal) (role uint))
    (begin
        (asserts! (is-valid-role role) ERR_INVALID_ROLE)
        (asserts! (check-permission tx-sender PERM_ASSIGN) ERR_UNAUTHORIZED)
        (asserts! (is-none (get-user-role user)) ERR_ROLE_EXISTS)
        
        (map-set UserRoles
            { user: user }
            {
                role: role,
                assigned-by: tx-sender,
                assigned-at: block-height,
                active: true
            }
        )
        (ok true)
    )
)

(define-public (revoke-role (user principal))
    (let (
        (role-data (unwrap! (get-user-role user) ERR_NO_ROLE))
    )
        (asserts! (check-permission tx-sender PERM_ASSIGN) ERR_UNAUTHORIZED)
        
        (map-set UserRoles
            { user: user }
            (merge role-data { active: false })
        )
        (ok true)
    )
)

(define-public (update-role-permissions (role uint) 
                                      (can-register bool)
                                      (can-verify bool)
                                      (can-audit bool)
                                      (can-assign bool))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-valid-role role) ERR_INVALID_ROLE)
        
        (map-set RolePermissions
            { role: role }
            {
                register: can-register,
                verify: can-verify,
                audit: can-audit,
                assign: can-assign
            }
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-user-role (user principal))
    (map-get? UserRoles { user: user })
)

(define-read-only (get-role-permissions (role uint))
    (map-get? RolePermissions { role: role })
)

(define-read-only (check-permission (user principal) (permission uint))
    (let (
        (role-data (unwrap! (get-user-role user) false))
        (permissions (unwrap! (get-role-permissions (get role role-data)) false))
    )
        (and (get active role-data)
             (if (is-eq permission PERM_REGISTER)
                 (get register permissions)
                 (if (is-eq permission PERM_VERIFY)
                     (get verify permissions)
                     (if (is-eq permission PERM_AUDIT)
                         (get audit permissions)
                         (if (is-eq permission PERM_ASSIGN)
                             (get assign permissions)
                             false)))))
    )
)

(define-private (is-valid-role (role uint))
    (or 
        (is-eq role ROLE_ADMIN)
        (is-eq role ROLE_VERIFIER)
        (is-eq role ROLE_AUDITOR)
    )
)