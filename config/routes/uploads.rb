# frozen_string_literal: true

# TUS resumable uploads (minimal TUS-inspired)
post "uploads", to: "tus_uploads#create", as: :uploads
match "uploads/:id", to: "tus_uploads#update", via: %i[patch head], as: :upload
