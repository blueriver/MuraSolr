<!---
   Copyright 2011 Blue River Interactive

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
--->
<cfcomponent extends="mura.plugin.pluginGenericEventHandler" output="false">

<cfset variables.collectionService="">
<cfset variables.rsAssigned="">
	
<cffunction name="onApplicationLoad" output="false">
<cfargument name="$">
	
	<cfset var rs=variables.pluginConfig.getAssignedSites()>
	<cfset var pApp=variables.pluginConfig.getApplication()>
	<cfset var contentGateway=getBean("contentGateway")>
	<cfif variables.configBean.getCompiler() eq "Adobe">
		<cfset variables.collectionService=createObject("component","collectionServiceAdobe").init(variables.pluginConfig)>
	<cfelse>
		<cfset variables.collectionService=createObject("component","collectionServiceDefault").init(variables.pluginConfig)>
	</cfif>
	<cfset variables.searchService=createObject("component","searchService").init(variables.pluginConfig,variables.collectionService)>
	
	<cfloop query="rs">
		<cfset variables.pluginConfig.addEventHandler(this,rs.siteid)>
	</cfloop>
	
	<cfset pApp.setValue("searchService",variables.searchService)>
	<cfset pApp.setValue("collectionService",variables.collectionService)>
	
	<cfset contentGateway.injectMethod("getPublicSearch#variables.pluginConfig.getPluginID()#",contentGateway.getPublicSearch)>
	<cfset contentGateway.injectMethod("getPublicSearch",replacementPublicSearchMethod)>
	<cfset contentGateway.injectMethod("getPrivateSearch#variables.pluginConfig.getPluginID()#",contentGateway.getPrivateSearch)>
	<cfset contentGateway.injectMethod("getPrivateSearch",replacementPrivateSearchMethod)>
	<cfset contentGateway.injectMethod("rsUseSolr",variables.rsAssigned)>
</cffunction>

<cffunction name="onFileCache" output="false">
<cfargument name="$">

	<cfset variables.collectionService.indexFileItem($.event("fileID"),$.event("fileExt"),$.event("siteID"))>

</cffunction>

<cffunction name="onFileCacheDelete" output="false">
<cfargument name="$">
	<cfset var rsfile=$.event("rsfile")>
	<cfset variables.collectionService.indexFileItem(rsfile.fileID,rsfile.fileExt,rsfile.siteid)>
</cffunction>

<cffunction name="onAfterContentSave" output="false">
<cfargument name="$">
	<cfset var content=$.event("contentBean")>
	<cfif content.getActive() and listFindNoCase("Page,Portal,Calender,Gallery,File,Link",content.getType()) >
		<cfset variables.collectionService.indexDBItem(content.getContentID(),content.getSiteID())>
	</cfif>
</cffunction>

<cffunction name="onAfterContentDelete" output="false">
<cfargument name="$">
	<cfset var content=$.event("contentBean")>
	<cfif listFindNoCase("Page,Portal,Calender,Gallery",content.getType()) >
		<cfset variables.collectionService.deleteDBItem(content.getContentID(),content.getSiteID())>
	</cfif>
</cffunction>

<cffunction name="replacementPublicSearchMethod" output="false">
	<cfargument name="siteid" type="string" required="true">
	<cfargument name="keywords" type="string" required="true">
	<cfargument name="tag" type="string" required="true" default="">
	<cfargument name="sectionID" type="string" required="true" default="">
	<cfargument name="categoryID" type="string" required="true" default="">
	
	<cfset var pConfig=application.pluginManager.getConfig("solr")>
	<cfset var rs=pConfig.getAssignedSites()>
	
	<cfif listFindNoCase(valueList(rs.siteID),arguments.siteID)>
		<cfreturn pConfig.getApplication().getValue("searchService").getPublicSearch(argumentCollection=arguments)>
	<cfelse>
		<cfreturn evaluate("getPublicSearch#pConfig.getPluginID()#(argumentCollection=arguments)")>
	</cfif>
</cffunction>	

<cffunction name="replacementPrivateSearchMethod" output="false">
	<cfargument name="siteid" type="string" required="true">
	<cfargument name="keywords" type="string" required="true">
	<cfargument name="tag" type="string" required="true" default="">
	<cfargument name="sectionID" type="string" required="true" default="">
	<cfargument name="searchType" type="string" required="true" default="default" hint="Can be default or image">
	
	<cfset var pConfig=application.pluginManager.getConfig("solr")>
	<cfset var rs=pConfig.getAssignedSites()>
	
	<cfif listFindNoCase(valueList(rs.siteID),arguments.siteID)>
		<cfreturn pConfig.getApplication().getValue("searchService").getPrivateSearch(argumentCollection=arguments)>
	<cfelse>
		<cfreturn evaluate("getPrivateSearch#pConfig.getPluginID()#(argumentCollection=arguments)")>
	</cfif>
</cffunction>

</cfcomponent>