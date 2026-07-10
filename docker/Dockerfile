FROM instrumentisto/flutter:3.27

# Set working directory
WORKDIR /app

# Install additional tools
RUN apt-get update && apt-get install -y \
    lcov \
    && rm -rf /var/lib/apt/lists/*

# Copy pubspec files first for dependency caching
COPY apps/opensuite/pubspec.yaml apps/opensuite/pubspec.yaml
COPY packages/core/pubspec.yaml packages/core/pubspec.yaml
COPY packages/storage/pubspec.yaml packages/storage/pubspec.yaml
COPY packages/ui_kit/pubspec.yaml packages/ui_kit/pubspec.yaml
COPY packages/l10n/pubspec.yaml packages/l10n/pubspec.yaml

# Get dependencies for each package
RUN cd packages/core && flutter pub get || true
RUN cd packages/l10n && flutter pub get || true
RUN cd packages/storage && flutter pub get || true
RUN cd packages/ui_kit && flutter pub get || true
RUN cd apps/opensuite && flutter pub get || true

# Copy the rest of the source
COPY . .

# Default command
CMD ["flutter", "test", "--coverage"]
