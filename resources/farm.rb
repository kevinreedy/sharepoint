property :name, kind_of: String, name_property: true
property :sql_fqdn, kind_of: String, required: true
property :configdb, kind_of: String, required: true, default: 'SP_Config'
property :passphrase, kind_of: String, required: true
property :farm_acct, kind_of: String, required: true
property :farm_pswd, kind_of: String, required: true
property :setup_acct, kind_of: String, required: true
property :setup_pswd, kind_of: String, required: true
property :admin_db, kind_of: String, default: 'SP_Admin'
property :run_central_admin, kind_of: [TrueClass, FalseClass], default: true
property :central_admin_port, kind_of: Integer, default: 5000
property :central_admin_auth, kind_of: String, default: 'NTLM'
property :svc_pool_acct, kind_of: String, required: true
property :svc_pool_pswd, kind_of: String, required: true
property :log_path, kind_of: String, default: 'C:\\SPLogs'
property :usage_db, kind_of: String, default: 'SP_Usage'
property :usage_log_dir, kind_of: String, default: 'C:\\UsageLogs'
property :state_svc_db, kind_of: String, default: 'SP_State'
property :dist_cache_sizemb, kind_of: Integer, default: 1024
property :dist_cache_firewall_rule, kind_of: [TrueClass, FalseClass], default: false
property :cache_provision_order, kind_of: Array

default_action :create

def load_current_resource
  @current_resource = Chef::Resource::SharepointFarm.new(@new_resource.name)
end

def whyrun_supported?
  true
end

action :create do
  dsc_resource 'CreateSPFarm' do
    resource :SPFarm
    property :Ensure, 'Present'
    property :DatabaseServer, new_resource.sql_fqdn
    property :FarmConfigDatabaseName, new_resource.configdb
    property :Passphrase, ps_credential(new_resource.passphrase)
    property :FarmAccount, ps_credential(new_resource.farm_acct, new_resource.farm_pswd)
    property :PsDscRunAsCredential, ps_credential(new_resource.setup_acct, new_resource.setup_pswd)
    property :AdminContentDatabaseName, new_resource.admin_db if new_resource.run_central_admin
    property :RunCentralAdmin, new_resource.run_central_admin
    property :CentralAdministrationPort, new_resource.central_admin_port if new_resource.run_central_admin
    property :CentralAdministrationAuth, new_resource.central_admin_auth if new_resource.run_central_admin
    timeout 1500
  end
  dsc_resource 'ServicePoolManagedAccount' do
    resource :SPManagedAccount
    property :Ensure, 'Present'
    property :AccountName, new_resource.svc_pool_acct
    property :Account, ps_credential(new_resource.svc_pool_acct, new_resource.svc_pool_pswd)
    property :PsDscRunAsCredential, ps_credential(new_resource.setup_acct, new_resource.setup_pswd)
  end
  dsc_resource 'ApplyDiagnosticLogSettings' do
    resource :SPDiagnosticLoggingSettings
    property :PsDscRunAsCredential, ps_credential(new_resource.setup_acct, new_resource.setup_pswd)
    property :LogPath, new_resource.log_path
    property :LogSpaceInGB, 5
    property :AppAnalyticsAutomaticUploadEnabled, false
    property :CustomerExperienceImprovementProgramEnabled, true
    property :DaysToKeepLogs, 7
    property :DownloadErrorReportingUpdatesEnabled, false
    property :ErrorReportingAutomaticUploadEnabled, false
    property :ErrorReportingEnabled, false
    property :EventLogFloodProtectionEnabled, true
    property :EventLogFloodProtectionNotifyInterval, 5
    property :EventLogFloodProtectionQuietPeriod, 2
    property :EventLogFloodProtectionThreshold, 5
    property :EventLogFloodProtectionTriggerPeriod, 2
    property :LogCutInterval, 15
    property :LogMaxDiskSpaceUsageEnabled, true
    property :ScriptErrorReportingDelay, 30
    property :ScriptErrorReportingEnabled, true
    property :ScriptErrorReportingRequireAuth, true
  end
  dsc_resource 'UsageApplication' do
    resource :SPUsageApplication
    property :Ensure, 'Present'
    property :Name, 'Usage Service Application'
    property :DatabaseName, new_resource.usage_db
    property :UsageLogCutTime, 5
    property :UsageLogLocation, new_resource.usage_log_dir
    property :UsageLogMaxFileSizeKB, 1024
    property :PsDscRunAsCredential, ps_credential(new_resource.setup_acct, new_resource.setup_pswd)
  end
  dsc_resource 'StateServiceApp' do
    resource :SPStateServiceApp
    property :Ensure, 'Present'
    property :Name, 'State Service Application'
    property :DatabaseName, new_resource.state_svc_db
    property :PsDscRunAsCredential, ps_credential(new_resource.setup_acct, new_resource.setup_pswd)
  end
  dsc_resource 'EnableDistributedCache' do
    resource :SPDistributedCacheService
    property :Ensure, 'Present'
    property :Name, 'AppFabricCachingService'
    property :CacheSizeInMB, new_resource.dist_cache_sizemb
    property :ServiceAccount, new_resource.svc_pool_acct
    property :PsDscRunAsCredential, ps_credential(new_resource.setup_acct, new_resource.setup_pswd)
    property :CreateFirewallRules, new_resource.dist_cache_firewall_rule
    property :ServerProvisionOrder, new_resource.cache_provision_order if new_resource.cache_provision_order
  end
end

action :join do
  dsc_resource 'JoinSPFarm' do
    resource :SPJoinFarm
    property :Ensure, 'Present'
    property :DatabaseServer, new_resource.sql_fqdn
    property :FarmConfigDatabaseName, new_resource.configdb
    property :Passphrase, ps_credential(new_resource.passphrase)
    property :PsDscRunAsCredential, ps_credential(new_resource.setup_acct, new_resource.setup_pswd)
    property :AdminContentDatabaseName, new_resource.admin_db if new_resource.run_central_admin
    property :RunCentralAdmin, new_resource.run_central_admin
  end
  dsc_resource 'EnableDistributedCache' do
    resource :SPDistributedCacheService
    property :Ensure, 'Present'
    property :Name, 'AppFabricCachingService'
    property :CacheSizeInMB, new_resource.dist_cache_sizemb
    property :ServiceAccount, new_resource.svc_pool_acct
    property :PsDscRunAsCredential, ps_credential(new_resource.setup_acct, new_resource.setup_pswd)
    property :CreateFirewallRules, new_resource.dist_cache_firewall_rule
    property :ServerProvisionOrder, new_resource.cache_provision_order if new_resource.cache_provision_order
  end
end
