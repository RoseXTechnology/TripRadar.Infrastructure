FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5330

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["Directory.Packages.props", "."]

# Dependencies
COPY ["TripRadar.Service/TripRadar.Server.csproj", "TripRadar.Service/"]

RUN dotnet restore "TripRadar.Service/TripRadar.Service.csproj"

COPY . .

WORKDIR "/src/TripRadar.Service"
RUN dotnet build "TripRadar.Service.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "TripRadar.Service.csproj" -c Release -o /app/publish /p:UseAppHost=false -p:ExcludeConfigFilesFromBuildOutput=true

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
COPY --from=build /src/TripRadar.Service/appsettings*.json ./
ENTRYPOINT ["dotnet", "TripRadar.Service.dll"]
