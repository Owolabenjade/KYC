;; Define a map to hold hashes of user credentials
(define-map user-credentials
  ((id uint)) ;; key is user id
  ((hash (buff 32))) ;; value is a hash of the credentials
)

;; Function to register a new user with their credentials hash
(define-public (register-new-user (id uint) (hash (buff 32)))
  (begin
    ;; Check if the user already exists in the map
    (asserts! (not (map-get? user-credentials ((id id))))
              (err u"User already exists"))

    ;; Insert the new user's hash into the credentials map
    (map-insert user-credentials
                ((id id))
                ((hash hash)))
    (ok u"Registration successful")
  )
)

;; Function to verify a user's credentials
(define-public (verify-user-credentials (id uint) (provided-hash (buff 32)))
  (let ((user-record (map-get? user-credentials ((id id)))))
    (match user-record
      record
        (if (eq? (get hash record) provided-hash)
            (ok u"User verified successfully")
            (err u"Credentials do not match"))
      (err u"No such user")
    )
  )
)

;; Function to update an existing user's credentials
(define-public (update-user-hash (id uint) (new-hash (buff 32)))
  (begin
    ;; Check if the user is registered
    (asserts! (is-some (map-get? user-credentials ((id id))))
              (err u"User not found"))

    ;; Update the hash in the credentials map
    (map-set user-credentials
             ((id id))
             ((hash new-hash)))
    (ok u"Credentials updated successfully")
  )
)
