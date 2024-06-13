FROM mcr.microsoft.com/dotnet/aspnet:8.0.6-cbl-mariner2.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0.300 AS build
WORKDIR /src
COPY ["sampleApp.csproj", "."]
RUN dotnet restore "./sampleApp.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "sampleApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "sampleApp.csproj" -c Release -o /app/publish

FROM base AS final
RUN yum upgrade -y && yum autoremove -y

RUN yum install shadow-utils -y
RUN useradd -u 1000 -ms /bin/bash aspnet
USER aspnet
WORKDIR /app

ENV APP_VERSION=$DOCKER_TAG
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "sampleApp.dll"]