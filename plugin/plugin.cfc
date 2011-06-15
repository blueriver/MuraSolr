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
<cfcomponent output="false" extends="mura.plugin.plugincfc">

<cffunction name="init" returntype="any" access="public" output="false">
	<cfargument name="pluginConfig"  type="any" default="">
	<cfset variables.pluginConfig = arguments.pluginConfig>
	<cfset variables.locHash=hash("#application.configBean.getPluginDir()#/#variables.pluginConfig.getDirectory()#")>
	<cfif application.configBean.getCompiler() eq "Adode">
		<cfset variables.util=createObject("component","pluginUtilAdobe")>
	<cfelse>
		<cfset variables.util=createObject("component","pluginUtilDefault")>
	</cfif>
</cffunction>

<cffunction name="update" output="false">
	<cfset super.update()>
	<cfset deleteAllCollections()>
</cffunction>
	
<cffunction name="delete" output="false">
	<cfset super.delete()>
	<cfset deleteAllCollections()>
</cffunction>

<cffunction name="deleteCollection" outout="false">
	<cfargument name="collectionName">
	<cfif collectionExists(arguments.collectionName)>
		<cfcollection action="delete" collection="#arguments.collectionName#">
	</cfif>
</cffunction>

<cffunction name="deleteAllCollections" outout="false">
<cfargument name="collectionName">
	<cfset var rs=variables.pluginConfig.getAssignedSites()>
	<cfset var temp="">
	
	<cfloop query="rs">
		<cfset deleteCollection(rs.siteID & "db" & variables.locHash)>
		<cfset deleteCollection(rs.siteID & "file" & variables.locHash)>
	</cfloop>
	
	<cfif directoryExists("application.configBean.getPluginDir()#/#variables.pluginConfig.getDirectory()#/collections")>
		<cfdirectory action="list" directory="#application.configBean.getPluginDir()#/#variables.pluginConfig.getDirectory()#/collections" name="rs" type="Dir">
		
		<cfloop query="rs">
			<cfif collectionExists(rs.name)>
				<cfset deleteCollection(rs.name)>
			<cfelseif left(rs.name,2) eq "CF" and len(rs.name) gt 3>
				<cfset temp=right(rs.name,len(rs.name)-2)>
				<cfset temp=left(temp,len(temp)-1)>
				<cfif collectionExists(temp)>
					<cfset deleteCollection(temp)>
				<cfelseif directoryExists("#rs.directory#/#rs.name#")>
					<cfdirectory action="delete" directory="#rs.directory#/#rs.name#">
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
</cffunction>

<cffunction name="collectionExists" access="private" output="false" returntype="boolean">
   <cfargument name="collectionName" type="string" required="true" />
   <cfset var rs = variables.util.getCollections() />

   <cfreturn listContainsNoCase(valueList(rs.Name),arguments.collectionName) />
</cffunction>

<cffunction name="toBundle" output="false">
	<cfset deleteAllCollections()>
</cffunction>

</cfcomponent>
