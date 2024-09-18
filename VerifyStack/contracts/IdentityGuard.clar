;; Define a map to hold hashes of user credentials
(define-map user-credentials
  { id: uint }
  { hash: (buff 32) }
)

;; Define a constant for the administrator's principal using a valid Stacks address
(define-constant admin-id 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Define constants for input validation
(define-constant MAX_ID u1000000)  ;; Maximum allowed user ID
(define-constant HASH_BYTE_LENGTH u32)  ;; Expected length of hash in bytes

;; Function to check if the caller is the admin
(define-read-only (is-admin (caller principal))
  (is-eq caller admin-id)
)

;; Function to log actions; this is a simple representation and might be expanded for more complex systems
(define-map actions-log
  { id: uint, action: (string-ascii 128), timestamp: uint }
  { details: (string-ascii 256) }
)

;; Function to register a new user with their credentials hash
(define-public (register-new-user (id uint) (hash (buff 32)))
  (begin
    ;; Input validation
    (asserts! (< id MAX_ID) (err u"Invalid user ID"))
    (asserts! (is-eq (len hash) HASH_BYTE_LENGTH) (err u"Invalid hash length"))

    ;; Ensure the ID is not already registered
    (asserts! (is-none (map-get? user-credentials { id: id }))
              (err u"User already exists"))

    ;; Only allow admin to register new users
    (asserts! (is-eq tx-sender admin-id)
              (err u"Not authorized"))

    ;; Insert the new user's hash into the credentials map
    (map-insert user-credentials
                { id: id }
                { hash: hash })

    ;; Log the action
    (map-insert actions-log
                { id: id, action: "Register", timestamp: block-height }
                { details: "New user registered" })
    
    (ok u"Registration successful")
  )
)

;; Function to verify a user's credentials
(define-read-only (verify-user-credentials (id uint) (provided-hash (buff 32)))
  (begin
    ;; Input validation
    (asserts! (< id MAX_ID) (err u"Invalid user ID"))
    (asserts! (is-eq (len provided-hash) HASH_BYTE_LENGTH) (err u"Invalid hash length"))

    (let ((user-record (map-get? user-credentials { id: id })))
      (match user-record
        user-data (if (is-eq (get hash user-data) provided-hash)
                      (ok u"User verified successfully")
                      (err u"Credentials do not match"))
        (err u"No such user")
      )
    )
  )
)

;; Function to update an existing user's credentials
(define-public (update-user-hash (id uint) (new-hash (buff 32)))
  (begin
    ;; Input validation
    (asserts! (< id MAX_ID) (err u"Invalid user ID"))
    (asserts! (is-eq (len new-hash) HASH_BYTE_LENGTH) (err u"Invalid hash length"))

    ;; Ensure the user is registered before updating
    (asserts! (is-some (map-get? user-credentials { id: id }))
              (err u"User not found"))

    ;; Only allow admin to update user credentials
    (asserts! (is-eq tx-sender admin-id)
              (err u"Not authorized"))

    ;; Update the hash in the credentials map
    (map-set user-credentials
             { id: id }
             { hash: new-hash })

    ;; Log the action
    (map-insert actions-log
                { id: id, action: "Update", timestamp: block-height }
                { details: "User credentials updated" })
    
    (ok u"Credentials updated successfully")
  )
)