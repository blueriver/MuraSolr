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
<cfinclude template="plugin/config.cfm" />
<cfset variables.langList="Brazilian,Chinese,cjk,Czech,Dutch,English,French,Greek,German,Russian,Thai">
<cfset variables.rsSites=variables.pluginConfig.getAssignedSites()>
<cfset variables.collectionService=variables.pluginConfig.getApplication().getValue("collectionService")>

<cfif isDefined("form.update")>
	<cfloop query="variables.rsSites">
		<cfif isDefined("form.#variables.rsSites.siteID#lang") and isDefined("form.#variables.rsSites.siteID#orig")
			and form["#variables.rsSites.siteID#lang"] neq form["#variables.rsSites.siteID#orig"]	>
			<cfset variables.pluginConfig.setCustomSetting("#variables.rsSites.siteID#_language",form["#variables.rsSites.siteID#lang"])>
			<cfset variables.collectionService.deleteSiteCollections(variables.rsSites.siteID)>
			<cfset variables.collectionService.createSiteCollections(variables.rsSites.siteID)>
		</cfif>
	</cfloop>
</cfif>
<cfsavecontent variable="body">
<cfoutput>
<h2>#variables.pluginConfig.getName()#</h2>
<p>This plugin enhances the default front end search query to also use Apache Solr.</p>
<cfif isDefined("form.update")>
<p class="notice">Your language settings have been saved.</p>
</cfif>
<h3>Language Settings</h3>
<form method="post">
<table class="stripe">
<tr>
<th class="varWidth">Site</th>
<th>Language</th>
</tr>
<cfloop query="variables.rsSites">
<tr>
<td class="varWidth">
#htmlEditFormat(application.settingsManager.getSite(variables.rsSites.siteID).getSite())#
</td>
<td class="administration"><select name="#variables.rsSites.siteID#Lang" id="lang#variables.rsSites.siteID#">
<cfset itemLang=variables.pluginConfig.getCustomSetting("#variables.rsSites.siteID#_language","English")>
<cfloop list="#variables.langList#" index="i">
<option value="#i#"<cfif itemLang eq i> selected</cfif>>#htmlEditFormat(i)#</option>
</cfloop>
</select><input type="hidden" name="#variables.rsSites.siteID#orig" value="#itemLang#">
</td>
</tr>
</cfloop>
</table>
<input type="submit" name="update" value="Update">
</form>
</cfoutput>
</cfsavecontent>
<cfoutput>
#application.pluginManager.renderAdminTemplate(body=body,pageTitle=variables.pluginConfig.getName())#
</cfoutput>

