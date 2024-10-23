<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					function formatJson(jsonContext, translations, prizeValues, prizeNamesDesc) 
					{
						var scenario = getScenario(jsonContext);
						var tranMap = parseTranslations(translations);
						var prizeMap = parsePrizes(prizeNamesDesc, prizeValues);
						return doFormatJson(scenario, tranMap, prizeMap);
					}

					function doFormatJson(scenario, tranMap, prizeMap) 
					{
						var boardGrid = scenario.split("|")[0];
						var	revealGrid = scenario.split("|")[1];
						var result = new ScenarioConvertor().convert(boardGrid, revealGrid);
						
						var r = [];
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
						r.push('<tr>');	
						r.push('<th class="tablehead" width="100%" colspan="5">');
						r.push(tranMap["baseTitle"]);
						r.push('</th>');
						r.push('</tr>');

						r.push('<tr>');
						r.push('<td class="tablehead" width="100%" colspan="5">');
						r.push(tranMap["playGrid"]);
						r.push('</td>');
						r.push('</tr>');
						result.playGridTable.forEach(function (e) 
						{
							r.push('<tr>');
							e.forEach(function (t) 
							{
								r.push('<td class="tablebody" width="20%">');
								var arr = t.split(",");
								if (t.indexOf("matched") > -1) 
								{
									r.push(tranMap[arr[0]] + "<br/> (" + tranMap["matchedLabel"] + ")");
								} 
								else if (t.indexOf("lineLabel") > -1) 
								{
									r.push(prizeMap[arr[0]] + " (" + tranMap[arr[1]] + ")");
								} 
								else if (t.indexOf("prize") > -1) 
								{
									r.push(prizeMap[arr[0]]);
								} 
								else 
								{
									r.push(tranMap[t]);
								}
								r.push('</td>');
							});
							r.push('</tr>');
						});
						r.push('<tr>');
						r.push('<td class="tablehead" width="100%" colspan="5">');
						r.push(tranMap["drawnLabel"]);
						r.push('</td>');
						r.push('</tr>');
						result.revealGridTable.forEach(function (e) 
						{
							r.push('<tr>');
							e.forEach(function (t) 
							{
								r.push('<td class="tablebody" width="20%">');
								var arr = t.split(",");
								if (t.indexOf("matched") > -1) 
								{
									r.push(tranMap[arr[0]] + "<br/> (" + tranMap["matchedLabel"] + ")");
								} 
								else 
								{
									r.push(tranMap[t]);
								}
								r.push('</td>');
							});
						//	r.push('</td>');
							r.push('</tr>');
						});

						r.push('</table>');
						return r.join('');
					}
							
					function getScenario(jsonContext) 
					{
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;
						scenario = scenario.replace(/\0/g, '');
						return scenario;
					}
						
					function parsePrizes(prizeNamesDesc, prizeValues) 
					{
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');
						var map = [];
						for (var idx = 0; idx < prizeNames.length; idx++) 
						{
							map[prizeNames[idx]] = convertedPrizeValues[idx];
						}
						return map;
					}
					
					function parseTranslations(translationNodeSet) 
					{
						var map = [];
						var list = translationNodeSet.item(0).getChildNodes();
						for (var idx = 1; idx < list.getLength(); idx++) 
						{
							var childNode = list.item(idx);
							if (childNode.name == "phrase") 
							{
								map[childNode.getAttribute("key")] = childNode.getAttribute("value");
							}
						}
						return map;
					}
						
					function Result(lines, playGridTable, revealGridTable, matchedCells) 
					{
						return {
							lines: lines,
							playGridTable: playGridTable,
							revealGridTable: revealGridTable,
							matchedCells: matchedCells
						};
					}

					function PlayLine(prize, playGrid, winLine, matchedCellIdxs) 
					{
						return {
							prize: prize,
							playGrid: playGrid,
							winLine: winLine,
							matchedCellIdxs: matchedCellIdxs,
							toString: prize + ", " + winLine + ", " + playGrid + ", " + matchedCellIdxs
						};
					}

					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
						
					function ScenarioConvertor() 
					{
						return {
							convert: function (boardGrid, revealGrid) 
							{
								var _boardGridArr = boardGrid.split(",");
								var _revealGridArr = revealGrid.split(",");
								var _gridDataArr = [];

								function _getGridDataIdx(gridData) 
								{
									return parseInt(gridData) - 1;
								}

								function _generateRevealGridAnchors() 
								{
									var _gridDataRange = 30;
									for (var idx = 0; idx < _gridDataRange; idx++) 
									{
										_gridDataArr[idx] = null;
									}
									for (idx = 0; idx < _revealGridArr.length; idx++) 
									{
										_gridDataArr[_getGridDataIdx(_revealGridArr[idx])] = _revealGridArr[idx];
									}
								}
								_generateRevealGridAnchors();
					
								function _verifyWin(playGridArr) 
								{
									var result = true;
									for (var idx = 0; idx < playGridArr.length; idx++) 
									{
										var r = _gridDataArr[_getGridDataIdx(playGridArr[idx])] != null;
										result = result && r;
									}
									return result;
								}

								function _fillGridLine(gridIdxArr) 
								{
									var playGridArr = [];
									for (var idx = 0; idx < gridIdxArr.length; idx++) 
									{
										playGridArr[idx] = _boardGridArr[gridIdxArr[idx]];
									}
									return playGridArr;
								}

								function _fillGridLine(gridIdxArr) 
								{
									var playGridArr = [];
									for (var idx = 0; idx < gridIdxArr.length; idx++) 
									{
										playGridArr[idx] = _boardGridArr[gridIdxArr[idx]];
									}
									return playGridArr;
								}

								function _generatePlayLine() 
								{
									var plArr = [];
									var prizeStr = "DCBAJIHGFE", playGridArr, winLine;
									var gridIdxArr = [
										[0, 1, 2, 3],
										[4, 5, 6, 7],
										[8, 9, 10, 11],
										[12, 13, 14, 15],
										[0, 4, 8, 12],
										[1, 5, 9, 13],
										[2, 6, 10, 14],
										[3, 7, 11, 15],
										[0, 5, 10, 15],
										[12, 9, 6, 3]
									];
									for (var idx = 0; idx < prizeStr.length; idx++) 
									{
										playGridArr = _fillGridLine(gridIdxArr[idx]);
										winLine = _verifyWin(playGridArr);
										plArr[idx] = new PlayLine(prizeStr.charAt(idx), playGridArr, winLine, gridIdxArr[idx]);
										if (winLine) 
										{
											winLines.push(plArr[idx]);
										}
									}
									return plArr;
								}
					
								var winLines = [];
								var matchedCells = [];
								var lines = _generatePlayLine();

								function _parseMatchedCells() 
								{
									var arr = [];
									_boardGridArr.forEach(function (e) {
										_revealGridArr.forEach(function (f) {
											if (e === f) 
											{
												arr.push(e);
											}
										});
									});
									matchedCells = arr.filter(function (elem, index, self) {
										return index == self.indexOf(elem);
									});
								}
								_parseMatchedCells();

								var playGridTable = [],
									revealGridTable = [];

								function _parsePlayGridTable() 
								{
									var prizeLevel = ["D,prize", "C,prize", "B,prize", "A,prize"]
									playGridTable.push(["F,lineLabel1", "J,prize", "I,prize", "H,prize", "G,prize"]);
									var idx = 0,
										jdx = 0;
									var a, b, c, d;
									for (idx = 0; idx < _boardGridArr.length; idx += 4, jdx++) 
									{
										a = _boardGridArr[idx];
										b = _boardGridArr[idx + 1];
										c = _boardGridArr[idx + 2];
										d = _boardGridArr[idx + 3];
										if (matchedCells.indexOf(a) > -1) 
										{
											a = a + ",matched";
										}
										if (matchedCells.indexOf(b) > -1) 
										{
											b = b + ",matched";
										}
										if (matchedCells.indexOf(c) > -1) 
										{
											c = c + ",matched";
										}
										if (matchedCells.indexOf(d) > -1) 
										{
											d = d + ",matched";
										}
										playGridTable.push([prizeLevel[jdx], a, b, c, d]);
									}
									playGridTable.push(["E,lineLabel2", "-", "-", "-", "-"]);
								}
							
								function _parseRevealGridTable() 
								{
									var idx = 0;
									var a, b, c;
									for (idx = 0; idx < _revealGridArr.length; idx += 3) 
									{
										a = _revealGridArr[idx];
										b = _revealGridArr[idx + 1];
										c = _revealGridArr[idx + 2];
										if (matchedCells.indexOf(a) > -1) 
										{
											a = a + ",matched";
										}
										if (matchedCells.indexOf(b) > -1) 
										{
											b = b + ",matched";
										}
										if (matchedCells.indexOf(c) > -1) 
										{
											c = c + ",matched";
										}
										revealGridTable.push([a, b, c]);
									}
								}
								_parsePlayGridTable();
								_parseRevealGridTable();

								return new Result(lines, playGridTable, revealGridTable, matchedCells);
							}
						};
					}
					]]>
				</lxslt:script>
			</lxslt:component>
			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>
				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
			
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
	
</xsl:stylesheet>
