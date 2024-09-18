;; Define a map to hold hashes of user credentials
(define-map user-credentials
  ((id uint)) ;; key is user id
  ((hash (buff 32))) ;; value is a hash of the credentials
)

;; Define a map for logging actions
(define-map actions-log
  ((id uint) (timestamp uint)) ;; key is user id and timestamp
  ((action (string-ascii 128))) ;; value is the action taken
)

;; Define an admin role using a constant variable
(define-constant admin-id u1)

;; Check if the caller is the admin
(define-read-only (is-admin (caller principal))
  (eq? caller (var-get admin-id))
)

;; Function to log actions
(define-private (log-action (id uint) (action-description (string-ascii 128)))
  (map-set actions-log
           ((id id) (timestamp block-height))
           ((action action-description)))
)

;; Function to register a new user with their credentials hash
(define-public (register-new-user (id uint) (hash (buff 32)))
  (begin
    ;; Admin privileges required
    (asserts! (is-admin tx-sender)
              (err u"Not authorized"))

    ;; Ensure the ID is not already registered
    (asserts! (is-none (map-get? user-credentials ((id id))))
              (err u"User already exists"))

    ;; Insert the new user's hash into the credentials map
    (map-insert user-credentials
                ((id id))
                ((hash hash)))

    ;; Log the registration action
    (log-action id u"User Registered")

    (ok u"Registration successful")
  )
)

;; Function to verify a user's credentials
(define-public (verify-user-credentials (id uint) (provided-hash (buff 32)))
  (let ((user-record (map-get? user-credentials ((id id)))))
    (match user-record
      record
        (if (eq? (get hash record) provided-hash)
            (begin
              (log-action id u"User Verified")
              (ok u"User verified successfully"))
            (err u"Credentials do not match"))
      (err u"No such user")
    )
  )
)

;; Function to update an existing user's credentials
(define-public (update-user-hash (id uint) (new-hash (buff 32)))
  (begin
    ;; Admin privileges required
    (asserts! (is-admin tx-sender)
              (err u"Not authorized"))

    ;; Ensure the user is registered before updating
    (asserts! (is-some (map-get? user-credentials ((id id))))
              (err u"User not found"))

    ;; Update the hash in the credentials map
    (map-set user-credentials
             ((id id))
             ((hash new-hash)))

    ;; Log the update action
    (log-action id u"Credentials Updated")

    (ok u"Credentials updated successfully")
  )
)
