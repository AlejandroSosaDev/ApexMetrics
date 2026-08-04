# syntax=docker/dockerfile:1

# ---- build ------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /src

# Project file first so this layer only invalidates when a dependency
# changes, not on every source edit.
COPY src/ApexMetrics.Api/ApexMetrics.Api.csproj src/ApexMetrics.Api/
RUN dotnet restore src/ApexMetrics.Api/ApexMetrics.Api.csproj

COPY src/ src/
RUN dotnet publish src/ApexMetrics.Api/ApexMetrics.Api.csproj \
    -c Release -o /app --no-restore

# ---- runtime ------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS runtime
WORKDIR /app

# curl is not in the slim runtime image by default; installed only so the
# HEALTHCHECK below can probe the API from inside its own container.
RUN apk add --no-cache curl

COPY --from=build /app .

# The aspnet base image ships a non-root "app" user for exactly this purpose.
USER app

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

# 127.0.0.1, not localhost: apex-ui's Dockerfile hit "localhost" resolving to
# the container's IPv6 loopback first even though the server only binds
# IPv4, producing a false-unhealthy status. Same fix applied here up front.
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \
    CMD curl -fsS http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["dotnet", "ApexMetrics.Api.dll"]
