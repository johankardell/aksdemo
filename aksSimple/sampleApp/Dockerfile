FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["sampleApp.csproj", "."]
RUN dotnet restore "./sampleApp.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "sampleApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "sampleApp.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
ENV APP_VERSION=$DOCKER_TAG
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "sampleApp.dll"]