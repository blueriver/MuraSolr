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
<cfcomponent output="false" extends="mura.cfobject">

<cfset variables.pluginConfig="">
<cfset variables.collectionDir="">
<cfset variables.locHash="">
<cfset variables.configBean = getBean("configBean") />
<cfset variables.collectionExtensions="pdf,doc,odt,docx,xls,xlsx">
<cfset variables.assignedSites="">
<cfset variables.assignedSites="">

<cffunction name="init" output="false">
<cfargument name="pluginConfig">
	<cfset variables.locHash=hash("#variables.configBean.getPluginDir()#/#arguments.pluginConfig.getDirectory()#")>
	<cfset variables.pluginConfig=arguments.pluginConfig>
	<cfset variables.assignedSites=variables.pluginConfig.getAssignedSites()>
	
	<cfset variables.collectionDir="#variables.configBean.getPluginDir()#/#arguments.pluginConfig.getDirectory()#/collections">

	<cfif not directoryExists(variables.collectionDir)>
   		<cfdirectory action="create" directory="#variables.collectionDir#">
	</cfif>
	
	<cfloop query="variables.assignedSites">
		<cfset createSiteCollections(variables.assignedSites.siteID)>
	</cfloop>
	<cfreturn this>
</cffunction>

<cffunction name="getCollectionName" output="false">
<cfargument name="siteID">
<cfargument name="type">
<cfreturn arguments.siteID & arguments.type & variables.locHash>
</cffunction>

<cffunction name="getCollectionLanguage" output="false">
<cfargument name="siteID">
<cfreturn variables.pluginConfig.getCustomSetting("#arguments.siteID#_language","English")>
</cffunction>

<cffunction name="collectionExists" output="false" returntype="boolean">
   <cfargument name="collectionName" type="string" required="true" />
   <cfset var rs = getCollections() />

   <cfreturn listContainsNoCase(valueList(rs.Name),arguments.collectionName) />
</cffunction>

<cffunction name="indexAllDB" output="false" returntype="void"> 
	<cfargument name="siteID">
 	<cfset var rs = "" />
	<cfset var collectionName=getCollectionName(arguments.siteID,"db")>
	<cfset var language=getCollectionLanguage(arguments.siteID)>
	
	<cfset deleteCollection(collectionName)>
	<cfset createCollection(collection=collectionName, language=language)>
	   	
	<!--- now populate the collection with content --->
	 <cfquery name="rs" datasource="#variables.configBean.getDatasource()#">
	      SELECT 
	          contentID,type,subtype,siteID,Title,Body,summary,tags,filename,credits  
	      FROM tcontent
	      WHERE 
		  active = 1
		  and type in ('Page','Portal','Calenda','Gallery','File','Link')
		  and siteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#">
	  </cfquery>
	
	<cfif rs.recordcount>
	  	<cfset querySetCell(rs,"body", stripMarkUp(rs.body))>
	  	<cfset querySetCell(rs,"summary", stripMarkUp(rs.summary))>
	  	
	  	<cfindex action="update" collection="#getCollectionName(arguments.siteID,'db')#" key="contentID" type="custom" query="rs" title="title" custom1="summary" custom2="tags" body="body" language="#getCollectionLanguage(arguments.siteID)#"/>
	</cfif>

</cffunction>

<cffunction name="indexDBItem" output="false" returntype="void">
<cfargument name="contentID">
<cfargument name="siteID">
	  <cfset var rs="">
	   	<!--- now populate the collection with content --->
	  <cfquery name="rs" datasource="#variables.configBean.getDatasource()#">
	      SELECT 
	      	  contentID,type,subtype,siteID,Title,Body,summary,tags,filename,credits   
	      FROM tcontent
	      WHERE 
	      contentID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.contentID#">
	      and siteID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#">
		  and active = 1
		  and type in ('Page','Portal','Calenda','Gallery','File','Link')
	  </cfquery>
	  
	  <cfif rs.recordcount>
	  	<cfset querySetCell(rs,"body", stripMarkUp(rs.body))>
	  	<cfset querySetCell(rs,"summary", stripMarkUp(rs.summary))>
	  	
	  	<cfindex action="update" collection="#getCollectionName(arguments.siteID,'db')#" key="contentID" type="custom" query="rs" title="title" custom1="summary" custom2="tags" body="body" language="#getCollectionLanguage(arguments.siteID)#"/>
	  </cfif>
</cffunction>

<cffunction name="deleteDBItem" output="false" returntype="void">
<cfargument name="contentID">
<cfargument name="siteID">

		<cfindex collection="#getCollectionName(arguments.siteID,'db')#"  
		action="delete"  
		key="#arguments.contentID#"> 
	
</cffunction>

<cffunction name="indexAllFiles" output="false" returntype="void">
<cfargument name="siteID">
	<cfset var collectionName=getCollectionName(arguments.siteID,"file")>
	<cfset var language=getCollectionLanguage(arguments.siteID)>

	<cfset deleteCollection(collectionName)>
	<cfset createCollection(collection=collectionName, language=language)>
	   	
	<cfindex collection="#collectionName#"  
	action="update"  
	type="path" 
	key="#variables.configBean.getFileDir()#/#arguments.siteID#/cache/file"
	extensions="#replace(variables.collectionExtensions,',',',.','ALL')#"
	language="#language#"> 

</cffunction>

<cffunction name="indexFileItem" output="false" returntype="void">
 <cfargument name="fileID">
 <cfargument name="fileExt">
 <cfargument name="siteID">

	<cfif listfindnocase(variables.collectionExtensions,arguments.fileExt)>
		<cfindex collection="#getCollectionName(arguments.siteID,'file')#"  
		action="update"  
		type="file" 
		key="#variables.configBean.getFileDir()#/#arguments.siteID#/cache/file/#arguments.fileID#.#arguments.fileEXT#"
		language="#getCollectionLanguage(arguments.siteID)#"> 
	</cfif>
</cffunction>

<cffunction name="deleteFileItem" output="false" returntype="void">
<cfargument name="fileID">
<cfargument name="fileExt">
<cfargument name="siteID">

	<cfif listfindnocase(variables.collectionExtensions,arguments.fileExt)>
		<cfindex collection="#getCollectionName(arguments.siteID,'file')#"  
		action="delete"  
		type="file" 
		key="#variables.configBean.getFileDir()#/#arguments.siteID#/cache/file/#arguments.fileID#.#arguments.fileEXT#"> 
	</cfif>
</cffunction>

<cffunction name="deleteCollection" outout="false">
<cfargument name="collectionName">
	<cfif collectionExists(arguments.collectionName)>
		<cfcollection action="delete" collection="#arguments.collectionName#">
	</cfif>
</cffunction>

<cffunction name="deleteSiteCollections" outout="false">
<cfargument name="siteID">
	<cfset deleteCollection(arguments.siteID & "db" & variables.locHash)>
	<cfset deleteCollection(arguments.siteID & "file" & variables.locHash)>
</cffunction>

<cffunction name="createSiteCollections" output="false">
<cfargument name="siteID">	
	<cfif not collectionExists(getCollectionName(arguments.siteID,"file"))>
		<cfset indexAllFiles(arguments.siteID) />
	</cfif>
		
	<cfif not collectionExists(getCollectionName(arguments.siteID,"db"))>
		<cfset indexAllDB(arguments.siteID) />
	</cfif>
</cffunction>

<cffunction name="deleteAllCollections" outout="false">
<cfargument name="collectionName">
	<cfset var rs="">
	<cfset var temp="">
	
	<cfloop query="variables.assignedSites">
		<cfset deleteSiteCollections(variables.assignedSites.siteID)>
	</cfloop>
	
	<cfdirectory action="list" directory="#variables.configBean.getPluginDir()#/#arguments.pluginConfig.getDirectory()#/collections" name="rs">
	
	<cfdirectory action="list" directory="#application.configBean.getPluginDir()#/#variables.pluginConfig.getDirectory()#/collections" name="rs" type="Dir">
	
	<cfloop query="rs">
		<cfif collectionExists(rs.name)>
			<cfset deleteCollection(rs.name)>
		<cfelseif left(rs.name,2) eq "CF" and len(rs.name) gt 2>
			<cfset temp=right(rs.name,len(rs.name)-2)>
			<cfset temp=left(temp,len(temp)-1)>
			<cfif collectionExists(temp)>
				<cfset deleteCollection(temp)>
			<cfelseif directoryExists("#rs.directory#/#rs.name#")>
				<cfdirectory action="delete" directory="#rs.directory#/#rs.name#">
			</cfif>
		</cfif>
	</cfloop>
</cffunction>

<cffunction name="purgeCollection" outout="false">
<cfargument name="collectionName">
	<cfif collectionExists(arguments.collectionName)>
		<cfcollection action="purge" collection="#arguments.collectionName#">
	</cfif>
</cffunction>

<cffunction name="getCollectionExtensions" output="false">
	<cfreturn variables.collectionExtensions>
</cffunction>

<cffunction name="search" output="false">
<cfargument name="keywords">
<cfargument name="type" default="file">
<cfargument name="siteID">
	<cfset var rs="">
	<cfset var collectionName=getCollectionName(arguments.siteID,arguments.type)>
	<cfset var language=getCollectionLanguage(arguments.siteID)>
	
	<cfif not collectionExists(collectionName)>
		<cfset createCollection(collection=collectionName, path="../collections",language=language)>
	</cfif>
	<cfif arguments.type eq "file">
		<cfsearch 
			name="rs" 
			collection="#collectionName#" 
			criteria="#arguments.keywords#" 
			language="#language#"
			ContextHighlightBegin='<strong>'
	    	ContextHighlightEnd="</strong>"
	   		ContextPassages="3"
	   		contextBytes="300"
	   		>
	<cfelse>
		<cfsearch 
			name="rs" 
			collection="#collectionName#" 
			criteria="#arguments.keywords#" 
			language="#language#"
			ContextHighlightBegin='<strong>'
	    	ContextHighlightEnd="</strong>"
	   		ContextPassages="3"
	   		contextBytes="300">
	
	</cfif>
	 
	 <cfreturn rs>
</cffunction>

<cffunction name="getCollections" ooutput="false">
	<!--- not implemented --->
</cffunction>

<cffunction name="createCollection" ooutput="false">
	<cfargument name="collection">
	<cfargument name="language">
	<!--- not implemented --->
</cffunction>

<cffunction name="stripMarkUp" returntype="string" output="false">
	<cfargument name="str" type="string">	
	<cfset var body=ReReplace(arguments.str, "<[^>]*>","","all")>
	<cfset var errorStr="">
	<cfset var regex1="(\[sava\]|\[mura\]).+?(\[/sava\]|\[/mura\])">
	<cfset var regex2="">
	<cfset var finder=reFindNoCase(regex1,body,1,"true")>

	<cfloop condition="#finder.len[1]#">
		<cfset body=replaceNoCase(body,mid(body, finder.pos[1], finder.len[1]),'')>
		<cfset finder=reFindNoCase(regex1,body,1,"true")>
	</cfloop>
	
	<cfreturn body />
</cffunction>

</cfcomponent>