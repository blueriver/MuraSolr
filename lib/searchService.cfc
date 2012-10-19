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
<cfcomponent extends="mura.cfobject" output="false">

<cfset variables.collectionService="">
<cfset variables.pluginConfig="">
<cfset variables.configBean="">

<cffunction name="init" output="false">
	<cfargument name="pluginConfig">
	<cfargument name="collectionService">
	<cfset variables.pluginConfig=arguments.pluginConfig>
	<cfset variables.collectionService=arguments.collectionService>
	<cfset variables.configBean=application.configBean>
	
	<cfreturn this>
</cffunction>

<cffunction name="getPrivateSearch" returntype="query" access="public" output="false">
	<cfargument name="siteid" type="string" required="true">
	<cfargument name="keywords" type="string" required="true">
	<cfargument name="tag" type="string" required="true" default="">
	<cfargument name="sectionID" type="string" required="true" default="">
	<cfargument name="searchType" type="string" required="true" default="default" hint="Can be default or image">
	
	<cfset var rs = "">
	<cfset var kw = trim(arguments.keywords)>
	<cfset var rsFileSearch=searchFileCollection(arguments.keywords,arguments.siteID)>
	<cfset var rsDBSearch=searchDBCollection(arguments.keywords,arguments.siteID)>
	<cfset var rsScore="">
	
	<cfquery name="rs"  datasource="#variables.configBean.getDatasource()#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
	SELECT tcontent.ContentHistID, tcontent.ContentID, tcontent.Approved, tcontent.filename, tcontent.Active, tcontent.Type, tcontent.OrderNo, tcontent.ParentID, 
	tcontent.Title, tcontent.menuTitle, tcontent.lastUpdate, tcontent.lastUpdateBy, tcontent.lastUpdateByID, tcontent.Display, tcontent.DisplayStart, 
	tcontent.DisplayStop,  tcontent.isnav, tcontent.restricted, count(tcontent2.parentid) AS hasKids,tcontent.isfeature,tcontent.inheritObjects,tcontent.target,tcontent.targetParams,
	tcontent.islocked,tcontent.releaseDate,tfiles.fileSize,tfiles.fileExt, 0 AS score, tcontent.nextn, tfiles.fileid,tfiles.filename as AssocFilename,tcontentstats.lockID
	FROM tcontent 
	LEFT JOIN tcontent tcontent2 ON (tcontent.contentid=tcontent2.parentid)
	LEFT JOIN tcontentstats ON (tcontent.contentid=tcontentstats.contentid
							and tcontent.siteID=tcontentstats.SiteID)
	<cfif arguments.searchType eq "image">
		Inner Join tfiles ON (tcontent.fileID=tfiles.fileID)
	<cfelse>
		Left Join tfiles ON (tcontent.fileID=tfiles.fileID)
	</cfif>

	<cfif len(arguments.tag)>
		Inner Join tcontenttags on (tcontent.contentHistID=tcontenttags.contentHistID)
	</cfif> 
	
	WHERE
	
	<cfif arguments.searchType eq "image">
	tfiles.fileext in ('png','gif','jpg','jpeg') AND
	</cfif>
	
	<cfif kw neq '' or arguments.tag neq ''>
         			(tcontent.Active = 1 
			  		AND tcontent.siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>)
					
					AND
					
					
					tcontent.type in ('Page','Portal','Calendar','File','Link','Gallery')
						
						<cfif len(arguments.sectionID)>
							and tcontent.path like  <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.sectionID#%">	
						</cfif>
				
						<cfif len(arguments.tag)>
							and tcontenttags.Tag= <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.tag)#"/> 
						<cfelse>
						
						and
						(
						<cfif rsDBSearch.recordcount or rsFileSearch.recordcount>
						
							<cfif rsFileSearch.recordcount>
								tcontent.fileID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rsFileSearch.fileID)#" list="true">)
							<cfelse>
								0=1
							</cfif>

							or 

							<cfif rsFileSearch.recordcount>
								tcontent.contenthistid in (
										select baseID from tclassextenddata
										where stringValue in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rsFileSearch.fileID)#" list="true">)
									)
							<cfelse>
								0=1
							</cfif>
							
							or
							
							<cfif rsDBSearch.recordcount>
								tcontent.contentID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rsDBSearch.contentID)#" list="true">)
							<cfelse>
								0=1
							</cfif>
							
						<cfelse>
							0=1
						</cfif>
						)
						</cfif>
					
		<cfelse>
		0=1
		</cfif>				
		
			
		GROUP BY tcontent.ContentHistID, tcontent.ContentID, tcontent.Approved, tcontent.filename, tcontent.Active, tcontent.Type, tcontent.OrderNo, tcontent.ParentID, 
		tcontent.Title, tcontent.menuTitle, tcontent.lastUpdate, tcontent.lastUpdateBy, tcontent.lastUpdateByID, tcontent.Display, tcontent.DisplayStart, 
		tcontent.DisplayStop,  tcontent.isnav, tcontent.restricted,tcontent.isfeature,tcontent.inheritObjects,
		tcontent.target,tcontent.targetParams,tcontent.islocked,tcontent.releaseDate,tfiles.fileSize,tfiles.fileExt, tcontent.nextn, tfiles.fileid, tfiles.filename,tcontentstats.lockID
	</cfquery> 
	
	<cfloop query="rs">
		<cfquery name="rsScore" dbtype="query">
			select score,context from rsDbSearch
			where contentID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#rs.contentID#">
		</cfquery>
		
		<cfif rsScore.recordcount>
			<cfset querySetCell(rs,"score",rsScore.score,rs.currentRow)>		
		</cfif>
		
		<cfif len(rs.fileID)>
			<cfquery name="rsScore" dbtype="query">
				select score,context from rsFileSearch
				where fileID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#rs.fileID#">
			</cfquery>
			
			<cfif rsScore.recordcount>
				<cfset querySetCell(rs,"score",rsScore.score,rs.currentRow)>
			</cfif>
		</cfif>
	</cfloop>
	
	<cfquery name="rs" dbtype="query">
	select * from rs order by score desc, title
	</cfquery>

	<cfreturn rs />
</cffunction>

<cffunction name="getPublicSearch" returntype="query" access="public" output="false">
	<cfargument name="siteid" type="string" required="true">
	<cfargument name="keywords" type="string" required="true">
	<cfargument name="tag" type="string" required="true" default="">
	<cfargument name="sectionID" type="string" required="true" default="">
	<cfargument name="categoryID" type="string" required="true" default="">
	<cfset var rs = "">
	<cfset var w = "">
	<cfset var c = "">
	<cfset var categoryListLen=listLen(arguments.categoryID)>
	<cfset var rsFileSearch=searchFileCollection(arguments.keywords,arguments.siteID)>
	<cfset var rsDBSearch=searchDBCollection(arguments.keywords,arguments.siteID)>
	<cfset var rsScore="">
	
	<cfquery name="rs" datasource="#variables.configBean.getDatasource()#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
	<!--- Find direct matches with no releasedate --->
	
	select tcontent.contentid,tcontent.contenthistid,tcontent.siteid,tcontent.title,tcontent.menutitle,tcontent.targetParams,tcontent.filename,tcontent.summary,tcontent.tags,
	tcontent.restricted,tcontent.releaseDate,tcontent.type,tcontent.subType,
	tcontent.restrictgroups,tcontent.target ,tcontent.displaystart,tcontent.displaystop,0 as Comments, 
	tcontent.credits, tcontent.remoteSource, tcontent.remoteSourceURL, 
	tcontent.remoteURL,tfiles.fileSize,tfiles.fileExt,tcontent.fileID,tcontent.audience,tcontent.keyPoints,
	tcontentstats.rating,tcontentstats.totalVotes,tcontentstats.downVotes,tcontentstats.upVotes, 0 as kids, 
	tparent.type parentType,tcontent.nextn,tcontent.path,tcontent.orderno,tcontent.lastupdate,tcontent.created,
	tcontent.created sortdate, 0 score,tfiles.filename as AssocFilename,tcontentstats.lockID,tcontentstats.majorVersion,tcontentstats.minorVersion
	from tcontent Left Join tfiles ON (tcontent.fileID=tfiles.fileID)
	Left Join tcontent tparent on (tcontent.parentid=tparent.contentid
						    			and tcontent.siteid=tparent.siteid
						    			and tparent.active=1) 
	LEFT JOIN tcontentstats ON (tcontent.contentid=tcontentstats.contentid
							and tcontent.siteID=tcontentstats.SiteID)

	
	
	<cfif len(arguments.tag)>
		Inner Join tcontenttags on (tcontent.contentHistID=tcontenttags.contentHistID)
	</cfif> 
		where
	
	         			(tcontent.Active = 1 
						AND tcontent.Approved = 1
				  		AND tcontent.siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> )
						
						AND
						   
						(
						  tcontent.Display = 2 
							AND 
							(
								(tcontent.DisplayStart <= #createodbcdate(now())#
								AND (tcontent.DisplayStop >= #createodbcdate(now())# or tcontent.DisplayStop is null)
								)
								OR  tparent.type='Calendar'
							)
							
							OR tcontent.Display = 1
						)
						
						
				AND
				tcontent.type in ('Page','Portal','Calendar','File','Link')
				
				AND tcontent.releaseDate is null
				
				<cfif len(arguments.sectionID)>
				and tcontent.path like  <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.sectionID#%">	
				</cfif>
				
				<cfif len(arguments.tag)>
					and tcontenttags.Tag= <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.tag)#"/> 
				<cfelse>
					and 
					(
					<cfif rsDBSearch.recordcount or rsFileSearch.recordcount>
						
						<cfif rsFileSearch.recordcount>
								tcontent.fileID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rsFileSearch.fileID)#" list="true">)
							<cfelse>
								0=1
							</cfif>

							or 

							<cfif rsFileSearch.recordcount>
								tcontent.contenthistid in (
										select baseID from tclassextenddata
										where stringValue in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rsFileSearch.fileID)#" list="true">)
									)
							<cfelse>
								0=1
							</cfif>
							
							or
							
							<cfif rsDBSearch.recordcount>
								tcontent.contentID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rsDBSearch.contentID)#" list="true">)
							<cfelse>
								0=1
							</cfif>
					
					<cfelse>
						0=1
					</cfif>
						
					)
				</cfif>
				
				and tcontent.searchExclude=0
				
				<cfif categoryListLen>
					  and tcontent.contentHistID in (
							select tcontentcategoryassign.contentHistID from 
							tcontentcategoryassign 
							inner join tcontentcategories 
							ON (tcontentcategoryassign.categoryID=tcontentcategories.categoryID)
							where (<cfloop from="1" to="#categoryListLen#" index="c">
									tcontentcategories.path like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#listgetat(arguments.categoryID,c)#%"/> 
									<cfif c lt categoryListLen> or </cfif>
									</cfloop>) 
					  )
				</cfif>
				
				<cfif request.muraMobileRequest>
				    and (tcontent.mobileExclude!=1 or tcontent.mobileExclude is null)
				</cfif>
				
				
	union all
	
	<!--- Find direct matches with releasedate --->
	
	select tcontent.contentid,tcontent.contenthistid,tcontent.siteid,tcontent.title,tcontent.menutitle,tcontent.targetParams,tcontent.filename,tcontent.summary,tcontent.tags,
	tcontent.restricted,tcontent.releaseDate,tcontent.type,tcontent.subType,
	tcontent.restrictgroups,tcontent.target ,tcontent.displaystart,tcontent.displaystop,0 as Comments, 
	tcontent.credits, tcontent.remoteSource, tcontent.remoteSourceURL, 
	tcontent.remoteURL,tfiles.fileSize,tfiles.fileExt,tcontent.fileID,tcontent.audience,tcontent.keyPoints,
	tcontentstats.rating,tcontentstats.totalVotes,tcontentstats.downVotes,tcontentstats.upVotes, 0 as kids, 
	tparent.type parentType,tcontent.nextn,tcontent.path,tcontent.orderno,tcontent.lastupdate,tcontent.created,
	tcontent.releaseDate sortdate, 0 score,tfiles.filename as AssocFilename,tcontentstats.lockID,tcontentstats.majorVersion,tcontentstats.minorVersion
	from tcontent Left Join tfiles ON (tcontent.fileID=tfiles.fileID)
	Left Join tcontent tparent on (tcontent.parentid=tparent.contentid
						    			and tcontent.siteid=tparent.siteid
						    			and tparent.active=1) 
	Left Join tcontentstats on (tcontent.contentid=tcontentstats.contentid
					    and tcontent.siteid=tcontentstats.siteid) 
	
	
	<cfif len(arguments.tag)>
		Inner Join tcontenttags on (tcontent.contentHistID=tcontenttags.contentHistID)
	</cfif> 
		where
	
	         			(tcontent.Active = 1 
						AND tcontent.Approved = 1
				  		AND tcontent.siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> )
						
						AND
						   
						(
						  tcontent.Display = 2 
							AND 
							(
								(tcontent.DisplayStart <= #createodbcdate(now())#
								AND (tcontent.DisplayStop >= #createodbcdate(now())# or tcontent.DisplayStop is null)
								)
								OR  tparent.type='Calendar'
							)
							
							OR tcontent.Display = 1
						)
						
						
				AND
				tcontent.type in ('Page','Portal','Calendar','File','Link')
				
				AND tcontent.releaseDate is not null
				
				<cfif len(arguments.sectionID)>
				and tcontent.path like  <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.sectionID#%">	
				</cfif>
				
				<cfif len(arguments.tag)>
					and tcontenttags.Tag= <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.tag)#"/> 
				<cfelse>
					and 
					(
					<cfif rsDBSearch.recordcount or rsFileSearch.recordcount>
						
						<cfif rsFileSearch.recordcount>
								tcontent.fileID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rsFileSearch.fileID)#" list="true">)
							<cfelse>
								0=1
							</cfif>

							or 

							<cfif rsFileSearch.recordcount>
								tcontent.contenthistid in (
										select baseID from tclassextenddata
										where stringValue in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rsFileSearch.fileID)#" list="true">)
									)
							<cfelse>
								0=1
							</cfif>
							
							or
							
							<cfif rsDBSearch.recordcount>
								tcontent.contentID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rsDBSearch.contentID)#" list="true">)
							<cfelse>
								0=1
							</cfif>
					
					<cfelse>
						0=1
					</cfif>
						
					)
				</cfif>
				
				and tcontent.searchExclude=0
				
				<cfif categoryListLen>
					  and tcontent.contentHistID in (
							select tcontentcategoryassign.contentHistID from 
							tcontentcategoryassign 
							inner join tcontentcategories 
							ON (tcontentcategoryassign.categoryID=tcontentcategories.categoryID)
							where (<cfloop from="1" to="#categoryListLen#" index="c">
									tcontentcategories.path like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#listgetat(arguments.categoryID,c)#%"/> 
									<cfif c lt categoryListLen> or </cfif>
									</cfloop>) 
					  )
				</cfif>
				
				<cfif request.muraMobileRequest>
				 	and (tcontent.mobileExclude!=1 or tcontent.mobileExclude is null)
				</cfif>				
	</cfquery>
	
	<cfloop query="rs">
		<cfquery name="rsScore" dbtype="query">
			select score,context from rsDbSearch
			where contentID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#rs.contentID#">
		</cfquery>
		
		<cfif rsScore.recordcount>
			<cfset querySetCell(rs,"score",rsScore.score,rs.currentRow)>
			<cfif len(trim(rsScore.context))>
				<cfset querySetCell(rs,"summary","<p>" & rsScore.context & "</p>",rs.currentRow)>
			</cfif>
		</cfif>
		
		<cfif len(rs.fileID)>
			<cfquery name="rsScore" dbtype="query">
				select score,context from rsFileSearch
				where fileID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#rs.fileID#">
			</cfquery>
			
			<cfif rsScore.recordcount>
				<cfset querySetCell(rs,"score",rsScore.score,rs.currentRow)>
				<cfif len(trim(rsScore.context))>
					<cfset querySetCell(rs,"summary","<p>" & rsScore.context & "</p>",rs.currentRow)>
				</cfif>
			</cfif>
		</cfif>
	</cfloop>
	
	<cfquery name="rs" dbtype="query">
		select *
		from rs 
		order by score desc, sortdate desc
	</cfquery>
	
	<cfreturn rs />
</cffunction>

<cffunction name="searchDBCollection" output="false">
<cfargument name="keywords">
<cfargument name="siteID">

<cfset var rsResult=queryNew("contentID,score,context","varchar,decimal,varchar")>
<cfset var rsRaw="">

<cfif len(arguments.keywords)>
	<cfset rsRaw=variables.collectionService.search(arguments.keywords,"db",arguments.siteID)>
	
	<cfquery name="rsRaw" dbtype="query">
		select * from rsRaw order by score desc
	</cfquery>
	
	<cfloop query="rsRaw">
		<cfset queryAddRow(rsResult,1)/>
		<cfset querysetcell(rsResult,"contentID",rsRaw.key,rsRaw.currentRow)/>
		<cfset querysetcell(rsResult,"score",rsRaw.score,rsRaw.currentRow)/>
		<cfset querysetcell(rsResult,"context",rsRaw.context,rsRaw.currentRow)/>
		
		<cfif rsRaw.currentRow eq 2000>
			<cfbreak>
		</cfif>
	</cfloop>
</cfif>

<cfreturn rsResult>
</cffunction>

<cffunction name="searchFileCollection" output="false">
<cfargument name="keywords">
<cfargument name="siteID">
<cfset var rsResult=queryNew("fileID,score,context","varchar,decimal,varchar")>
<cfset var rsRaw="">

<cfif len(arguments.keywords)>
	<cfset rsRaw=variables.collectionService.search(arguments.keywords,"file",arguments.siteID)>
	
	<cfquery name="rsRaw" dbtype="query">
		select * from rsRaw order by score desc
	</cfquery>
	
	<cfloop query="rsRaw">
		<cfset queryAddRow(rsResult,1)/>
		<cfset querysetcell(rsResult,"fileID",listLast(listFirst(rsRaw.url,"."),"/"),rsRaw.currentRow)/>
		<cfset querysetcell(rsResult,"score",rsRaw.score,rsRaw.currentRow)/>
		<cfset querysetcell(rsResult,"context",rsRaw.context,rsRaw.currentRow)/>
		
		<cfif rsRaw.currentRow eq 2000>
			<cfbreak>
		</cfif>
	</cfloop>
</cfif>

<cfreturn rsResult>
</cffunction>

</cfcomponent>