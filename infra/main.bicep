param name string
param location string = resourceGroup().location
param loc string = 'krc'
param publishname string = 'junhee'
param publishemail string = 'dlwns7267@naver.com'
param workspaceId string = '/subscriptions/b3751e05-ee1c-4464-b33c-732591e9e936/resourceGroups/rg-ocaljhh-krc/providers/Microsoft.OperationalInsights/workspaces/wrkspc-ocaljhh-krc'


var rg = 'rg-${name}-${loc}'
var fncappname = 'fncapp-${name}-${loc}'

resource st 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'st${name}${loc}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
resource csplan 'Microsoft.Web/serverfarms@2021-03-01' = { //serverfarm에서 asp properties확인 가능
  name : 'csplan-${name}-${loc}'
  location: location
  kind: 'functionapp'
  sku: {  //서버리스 app
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0 
  }
  properties: {
    reserved: false //windows
  }
}

resource fncapp 'Microsoft.Web/sites@2021-03-01' = {
  name : fncappname
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: csplan.id //앱서비스 플랜 종속
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsSecretStorageType' //저장소 종속
          value: st.id
        }
      ]
    }
  }
}
resource wrkspc 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'wrkspc-${name}-${loc}'
  location: location
  properties: {
      sku: {
          name: 'PerGB2018' //sku 이름 8종류
      }
      retentionInDays: 30 //보존 기간
      workspaceCapping: {
          dailyQuotaGb: -1
      }
      publicNetworkAccessForIngestion: 'Enabled'
      publicNetworkAccessForQuery: 'Enabled'
  }
}

//insights
resource appins 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appins-${name}-${loc}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    IngestionMode: 'LogAnalytics' //모드 3가지. loganalytics의 id를 가져오려면 해당 모드로 설정
    Request_Source: 'rest'
    RetentionInDays: 30 //보존 기간
    WorkspaceResourceId: workspaceId   //=> loganalytics의 id를 입력(실제로는 Resource ID?)
  }
}

//apimanagement
resource apim 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: 'apim-${name}-${loc}'
  location: location
  sku: {
      name: 'Consumption' //6가지 중 소비
      capacity: 0 //용량은 0으로 설정해야함
  }
  properties: {
      publisherName: publishname //개인정보는 파라미터로 받아오기
      publisherEmail: publishemail
      restore: true
  }
}
output rn string = rg //실행시키면 실행한 결과값이 나옴(다른 bicep파일에서 참조할 수 있음) - 모듈화 시킬 때 유용

