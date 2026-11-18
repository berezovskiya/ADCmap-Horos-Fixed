//
//  ADC_ToolGraph.m
//  ADC_Tool
//
//  Created by Kyung Sung on 2/28/10.
//  Copyright 2010 Stanford University. All rights reserved.
//  kyungs@stanford.edu
//

#import "ADC_ToolGraph.h"
#import "Horos/DICOMExport.h"
#import "Horos/BrowserController.h"


// AppKit raises an exception for a path point that is not a finite number. Horos logged such exceptions and
// went on; a host that ends the process on an uncaught exception (IsiX) quits instead. A graph with no usable
// range (one b-value, a flat signal, nothing measured yet) produces exactly such points, so every point
// passes through here, and -drawRect: draws the empty graph when the ranges cannot be drawn at all.
static inline NSPoint ADCSafePoint(NSPoint p)
{
	if (!isfinite(p.x)) p.x = 0;
	if (!isfinite(p.y)) p.y = 0;
	return p;
}

@implementation ADC_ToolGraph

- (id) initWithFrame:(NSRect) rect 
{
     if (![super initWithFrame:rect])
		return nil;
	
	// Initialize Values
	numValueROI = 0;
	
	NSLog(@"initWithFrame!");	
	
	return self;
    
}

- (void) setParameters: (long) nnTime :(float *) meanY :(float *) minY :(float *) maxY :(float *) timeX :(int *) minX :(int *) maxX :(int *) numROI :(NSMutableArray *) roiNameList :(NSMutableArray *) roiColorList :(float *) stdY :(float *) minimumY :(float *) maximumY :(int)curSlice :(int)maxSlice
{
	// Set Arrays
	nnTimeHere	= nnTime;
	minValueY	= *minY;
	maxValueY	= *maxY;
	minValueX	= *minX;
	maxValueX	= *maxX;
	numValueROI = *numROI;
	roiNameListHere	 = roiNameList;
	roiColorListHere = roiColorList;
	maxZZ = maxSlice;
	curZZ = curSlice;
	
	flag_blank = 0;
	
	NSLog(@"nnTimeHere is %ld", nnTimeHere);
	NSLog(@"numValueROI is %d", numValueROI);
	
	for (idroi = 0; idroi < numValueROI; idroi++) 
	{ 
		for (i = 0; i < nnTimeHere; i++) 
		{
			meanHere[idroi][i]		= *meanY++;
			stdYHere[idroi][i]		= *stdY++;
			minimumYHere[idroi][i]	= *minimumY++;
			maximumYHere[idroi][i]	= *maximumY++;
		}
	}
	
	for (i = 0; i < nnTimeHere; i++)
	{
		timeXHere[i] = *timeX++;
		//		NSLog(@"timeXHere is %f",timeXHere[i]);
	}
	
	[self setNeedsDisplay: YES];
}

- (void) drawBlank 
{
	flag_blank = 1;
	
	[self setNeedsDisplay: YES];
	NSLog(@"drawBlank!");
}	

- (void) makeSelectedRegion:(int) minP :(int) maxP
{
	if (minP == 0L && maxP == 0L)
	{
		selectedRegion = 0;
		minPoint = 0;
		maxPoint = 0;
	}
	else
	{
		selectedRegion = 1;
		minPoint = minP;
		maxPoint = maxP;
		//NSLog(@"maxPoint is %d and minPoint is %d",maxPoint,minPoint);
	}
	[self setNeedsDisplay: YES];
}

-(void) dealloc 
{
	[path release];
	[bgColor release];
	[txtColor release];
	[roiNameListHere release];
	[roiColorListHere release];
	
	[super dealloc];
}

#pragma mark-
#pragma mark Plot 

- (void) drawXAxis:(float *) timeX :(int) minX :(int) maxX :(int) numXaxis :(int) stepTime :(NSRect) r
{
	NSLog(@"drawXAxis Starts!");
	
	// FIX: Перевірка на ділення на нуль та NaN
	float timeDiff = timeX[maxX] - timeX[minX];
	if (timeDiff <= 0.0 || isnan(timeDiff) || isinf(timeDiff)) {
		NSLog(@"WARNING: Invalid time difference: %f (timeX[%d]=%f, timeX[%d]=%f). Skipping X-axis drawing.", 
			  timeDiff, maxX, timeX[maxX], minX, timeX[minX]);
		return;
	}
	
	float xWidth = r.size.width * (float)stepTime / timeDiff;
	
	// FIX: Додаткова перевірка результату обчислення
	if (isnan(xWidth) || isinf(xWidth) || xWidth <= 0.0) {
		NSLog(@"WARNING: Invalid xWidth calculated: %f. Using default value.", xWidth);
		xWidth = 100.0; // Значення за замовчуванням
	}
	
	CGFloat startGap;
	
	if (minX != 0)
		startGap = 45.0 + xAxisLoc[0] - r.origin.x;
	else
		startGap = 45.0;
	
	NSRect frame = NSMakeRect(startGap, 20, 10, 15);
	NSMatrix *axisX = [[NSMatrix alloc] initWithFrame: frame];
	[axisX setCellClass:[NSTextFieldCell class]];
	[self replaceSubview:[[self subviews] objectAtIndex:0] with:axisX];
	
	NSSize gapSize = NSMakeSize (30.0, 15.0);
	[axisX setCellSize:gapSize];
	
	int currentColumns	= [axisX numberOfColumns];
	// Empty NSMatrix
	while (currentColumns != 0)
	{ 
		[axisX removeColumn:currentColumns-1];
		currentColumns	= [axisX numberOfColumns];
	}
	
	// Define intercell space
	gapSize = NSMakeSize(xWidth-30.0, 0);
	
	// FIX: Перевірка розміру перед встановленням
	if (isnan(gapSize.width) || isinf(gapSize.width) || gapSize.width < 0.0) {
		NSLog(@"WARNING: Invalid gapSize.width: %f. Using default.", gapSize.width);
		gapSize = NSMakeSize(70.0, 0); // Значення за замовчуванням
	}
	
	[axisX setIntercellSpacing:gapSize];
	
	// Add columns
	for (i = 0; i < numXaxis+1; i++)
		[axisX addColumn]; 
	[axisX sizeToCells];
	
	// Add time values
	NSArray *cells = [axisX cells];
	NSString *tValue;
	for (i = 0; i < numXaxis+1; i++)
	{
		tValue  = [[NSString alloc] initWithFormat:@"%.0f",xAxisTime[i]];
		[[cells objectAtIndex:i] setStringValue:tValue];
		[[cells objectAtIndex:i] setAlignment:NSCenterTextAlignment];
		[[cells objectAtIndex:i] setFont:[NSFont labelFontOfSize:8.0]];
		[[cells objectAtIndex:i] setTextColor:txtColor];
	}
	
	// Draw x-axis ticks
	NSPoint p1,p2;
	for (i = 0; i < numXaxis+1; i++) 
	{
		path = [[NSBezierPath alloc] init];
		[path setLineWidth:1];
		
		p1.x = xAxisLoc[i];
		p1.y = r.origin.y-3;
		p2.x = xAxisLoc[i];
		p2.y = r.origin.y;
		
		[path moveToPoint:ADCSafePoint(p1)];
		[path lineToPoint:ADCSafePoint(p2)];
		[txtColor set];
		
		[path stroke];
	}
	[tValue release];
    NSLog(@"drawXAxis Done!");

}

- (void) drawYAxis:(float) minY :(float) maxY :(int) numYaxis :(int) stepValue :(NSRect) r 
{
	NSLog(@"drawYAxis Starts!");
	
	// FIX: Перевірка на ділення на нуль
	float valueDiff = maxY - minY;
	if (valueDiff <= 0.0 || isnan(valueDiff) || isinf(valueDiff)) {
		NSLog(@"WARNING: Invalid value difference: %f (maxY=%f, minY=%f). Skipping Y-axis drawing.", 
			  valueDiff, maxY, minY);
		return;
	}
	
	float yHeight = r.size.height * (float)stepValue / valueDiff;
	
	// FIX: Додаткова перевірка результату
	if (isnan(yHeight) || isinf(yHeight) || yHeight <= 0.0) {
		NSLog(@"WARNING: Invalid yHeight calculated: %f. Using default value.", yHeight);
		yHeight = 100.0;
	}
	
	NSRect frame = NSMakeRect(17, 35, 40, 15);
	NSMatrix *axisY = [[NSMatrix alloc] initWithFrame:frame]; 
	[axisY setCellClass:[NSTextFieldCell class]];
	[self replaceSubview:[[self subviews] objectAtIndex:2] with:axisY];
	
	NSSize gapSize = NSMakeSize (40.0, 11.0);
	//[axisY initWithFrame:NSMakeRect(20, yAxisLoc[1], 40, 100)];
	[axisY setCellSize:gapSize];
	
	int currentRows	= [axisY numberOfRows];
	// Empty NSMatrix
	while (currentRows != 0)
	{ 
		[axisY removeRow:currentRows-1];
		currentRows	= [axisY numberOfRows];
	}
	
	// Define intercell space
	gapSize = NSMakeSize(40.0, yHeight-11.0);
	
	// FIX: Перевірка розміру перед встановленням
	if (isnan(gapSize.height) || isinf(gapSize.height) || gapSize.height < 0.0) {
		NSLog(@"WARNING: Invalid gapSize.height: %f. Using default.", gapSize.height);
		gapSize = NSMakeSize(40.0, 70.0);
	}
	
	[axisY setIntercellSpacing:gapSize];
	
	// Add columns
	for (i = 0; i < numYaxis+1; i++)
		[axisY addRow]; 
	[axisY sizeToCells];
	
	// Add time values
	NSArray *cells = [axisY cells];
	NSString *tValue;
	for (i = 0; i < numYaxis+1; i++)
	{
		//		if (typeSignal2.indexOfSelectedItem == 1)
		tValue  = [[NSString alloc] initWithFormat:@"%.0f",yAxisValue[numYaxis-i]];
		//		else
		//			tValue  = [[NSString alloc] initWithFormat:@"%.0f",yAxisValue[numYaxis-i]];
		[[cells objectAtIndex:i] setStringValue:tValue];
		[[cells objectAtIndex:i] setAlignment:NSRightTextAlignment];
		[[cells objectAtIndex:i] setFont:[NSFont labelFontOfSize:9.0]];
		[[cells objectAtIndex:i] setTextColor:txtColor];
	}
	
	// Draw y-axis ticks
	NSPoint p1,p2;
	for (i = 0; i < numYaxis+1; i++) 
	{
		path = [[NSBezierPath alloc] init];
		[path setLineWidth:1];
		
		p1.y = yAxisLoc[i];
		p1.x = r.origin.x;
		p2.y = yAxisLoc[i];
		p2.x = r.origin.x-3;
		
		[path moveToPoint:ADCSafePoint(p1)];
		[path lineToPoint:ADCSafePoint(p2)];
		[txtColor set];
		
		[path stroke];
	}
	
	[tValue release];
    NSLog(@"drawYAxis Done!");

}


- (void) drawSelectedRegion:(NSRect) r
{
	NSLog(@"drawSelectedRegion Starts!");
	float p1, p2;
	int minNew, maxNew;
	
	if (minValueX > minPoint)
		minNew = minValueX;
	else
		minNew = minPoint;
	
	if (maxValueX < maxPoint)
		maxNew = maxValueX;
	else
		maxNew = maxPoint;
	
	p1 = (float)(timeXHere[minNew]-timeXHere[minValueX])/(float)(timeXHere[maxValueX]-timeXHere[minValueX])*r.size.width;
	p2 = (float)(timeXHere[maxNew]-timeXHere[minNew])/(float)(timeXHere[maxValueX]-timeXHere[minValueX])*r.size.width;
	
	NSRect b = NSMakeRect(r.origin.x+p1, r.origin.y, p2, r.size.height);
	
	// Fill the view with Colors
	[[NSColor grayColor] set];
	[NSBezierPath fillRect:b];
    NSLog(@"drawSelectedRegion Done!");
}

- (void) drawXGrid:(NSRect) r
{
	NSPoint p1,p2;
    NSLog(@"drawXGrid Starts!");

	// X-grid	
	for (i = minValueX; i < maxValueX-1; i++) 
	{
		path = [[NSBezierPath alloc] init];
		CGFloat lineDash[2];
		lineDash[0] = 5.0;  //segment painted with stroke color
		lineDash[1] = 2.0;  //segment not painted with a color
		[path setLineDash:lineDash count:2 phase:0.0];
		[path setLineWidth:0.3];
		
		p1.x = r.origin.x+r.size.width*(float)(timeXHere[i]-timeXHere[minValueX])/(float)(timeXHere[maxValueX]-timeXHere[minValueX]);
		p1.y = r.origin.y;
		p2.x = r.origin.x+r.size.width*(float)(timeXHere[i]-timeXHere[minValueX])/(float)(timeXHere[maxValueX]-timeXHere[minValueX]);
		p2.y = r.origin.y+r.size.height;
		
		[path moveToPoint:ADCSafePoint(p1)];
		[path lineToPoint:ADCSafePoint(p2)];
		[txtColor set];
		
		[path stroke];
	}
    NSLog(@"drawXGrid Done!");

}

- (void) drawYGrid:(int) numYaxis :(NSRect) r
{
	NSPoint p1,p2;
    NSLog(@"drawYGrid Starts!");

	// Y-grid	
	for (i = 0; i < numYaxis+1; i++) 
	{
		path = [[NSBezierPath alloc] init];
		CGFloat lineDash[2];
		lineDash[0] = 5.0;  //segment painted with stroke color
		lineDash[1] = 2.0;  //segment not painted with a color
		[path setLineDash:lineDash count:2 phase:0.0];
		[path setLineWidth:0.3];
		
		p1.x = r.origin.x;
		p1.y = yAxisLoc[i];
		p2.x = r.origin.x+r.size.width;
		p2.y = yAxisLoc[i];
		
		[path moveToPoint:ADCSafePoint(p1)];
		[path lineToPoint:ADCSafePoint(p2)];
		[txtColor set];
		
		[path stroke];
	}
    NSLog(@"drawYGrid Done!");

}

- (void) drawLegend:(NSRect) r
{
    NSLog(@"drawLegend Starts!");

	float xHere, yHere;
	int offset, numRec;

	// Determine which side
	if ([typeSignal2 indexOfSelectedItem] == 0)
		offset = 8;
	else
		offset = 10;
	
	// Legends at the Right side
	numRec = numValueROI;
	xHere = r.origin.x+r.size.width+offset;
	yHere = r.origin.y+r.size.height-5.0-15.0;
	
	// Erase all the previous settings
	while ([legendName numberOfRows] != 0)
		[legendName removeRow:[legendName numberOfRows]-1];
	
	// Redraw the matrix
	int ii;
	for (ii = 0; ii < numRec; ii++)
	{
		[legendName addRow];
		NSTextFieldCell *cellTmp = [legendName cellAtRow:ii column:0];
		[cellTmp setFont:[NSFont labelFontOfSize:9.0]];
		
		[cellTmp setAlignment:NSLeftTextAlignment];
		[cellTmp setTextColor:txtColor];
		[cellTmp setStringValue:[roiNameListHere objectAtIndex:ii]];
	}
	
	[legendName sizeToCells];
	[legendName setFrameOrigin: NSMakePoint(xHere+12.0, yHere-15.0*(numRec-1))];
	
	// Draw the color boxes
	for (ii = 0; ii < numRec; ii++)
	{
		path = [[NSBezierPath alloc] init];
		NSRect b = NSMakeRect(xHere, yHere-15.0*(ii), 8.0, 8.0);
		
		[[roiColorListHere objectAtIndex:ii] set];
		//	[NSBezierPath fillRect:b];
		[path appendBezierPathWithRect:b];
		[path fill];
		[txtColor set];
		[path stroke];
	}
    NSLog(@"drawLegend Done!");

}


- (void) drawPlot:(NSRect) r
{
    NSLog(@"drawPlot Starts!");

	int ii;	
	NSPoint p1,p2;
	
	// Plot the Mean lines
	for (idroi = 0; idroi < numValueROI; idroi++)
	{
		ii = 0;
		path = [[NSBezierPath alloc] init];
		[path setLineWidth:1];
		
		while (ii < nnTimeHere)
		{
			if (ii < minValueX)
			{
				ii++;
			}
			else if (ii == minValueX)
			{
				p1.x = r.origin.x+r.size.width*(float)(timeXHere[ii]-timeXHere[minValueX])/(float)(timeXHere[maxValueX]-timeXHere[minValueX]);
				p1.y = r.origin.y+r.size.height*(float)(meanHere[idroi][ii]-minValueY)/(float)(maxValueY-minValueY);
				[path moveToPoint:ADCSafePoint(p1)];
				
				ii++;
			}
			else if (ii <= maxValueX)
			{
				p2.x = r.origin.x+r.size.width*(float)(timeXHere[ii]-timeXHere[minValueX])/(float)(timeXHere[maxValueX]-timeXHere[minValueX]);
				p2.y = r.origin.y+r.size.height*(float)(meanHere[idroi][ii]-minValueY)/(float)(maxValueY-minValueY);
				[path lineToPoint:ADCSafePoint(p2)];
				
				ii++;
			}
			else
			{
				ii++;
			}
		}
		[[roiColorListHere objectAtIndex:idroi] set];
		[path stroke];
	}
    NSLog(@"drawPlot Done!");

}

- (void) nameAxes
{
    NSLog(@"nameAxes Starts!");

	NSRect bounds = [self bounds];
	float x = bounds.origin.x+bounds.size.width/2.0-15.0;
	float y = bounds.origin.y+5.0;
	NSString *nameX;
	
	NSMutableParagraphStyle *paragraphStyle;
    paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	NSDictionary *attrsDictionary;
	attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys: 
					   [NSFont labelFontOfSize:10.0], NSFontAttributeName, 
					   txtColor, NSForegroundColorAttributeName,
					   paragraphStyle, NSParagraphStyleAttributeName, nil];
	
	// Draw axis names
	nameX = [[NSString alloc] initWithFormat:@"Time [msec]"];
	[nameX drawAtPoint:NSMakePoint(x,y) withAttributes:attrsDictionary];
	[nameX release];
    
	x = bounds.origin.x+3.0;
	y = bounds.origin.y+bounds.size.height/2.0-8.0;
	
	NSAffineTransform *xform;
	xform = [NSAffineTransform transform];
	[xform rotateByDegrees:90];
	[xform concat];
	
	if ([typeSignal2 indexOfSelectedItem] == 0)
	{
		nameX = [[NSString alloc] initWithFormat:@"Mean ADC [um^2/sec x1000]"];
	}
	else if ([typeSignal2 indexOfSelectedItem] == 1)
	{
		nameX = [[NSString alloc] initWithFormat:@"Mean Signal [a.u.]"];
	}
	else if ([typeSignal2 indexOfSelectedItem] == 2)
	{
		nameX = [[NSString alloc] initWithFormat:@"Ratio of Signal to z=0 slice"];
	}
	else if ([typeSignal2 indexOfSelectedItem] == 3)
	{
		nameX = [[NSString alloc] initWithFormat:@"Ratio of Signal to z=%d",curZZ];
	}
	
	[nameX drawAtPoint:NSMakePoint(y,x) withAttributes:attrsDictionary];
	[nameX release];
	
	xform = [NSAffineTransform transform];
	[xform rotateByDegrees:-90];
	[xform concat];
	
	[paragraphStyle release];
    NSLog(@"nameAxes Done!");
}

- (void) drawRect:(NSRect)rect
{
	NSLog(@"drawRect starts!");
	
	// Select text and background colors
    txtColor = [NSColor blackColor];
    bgColor  = [NSColor whiteColor];
	NSRect bounds = [self bounds];
	
	// Draw boundart box and line
	NSRect r = NSMakeRect(bounds.origin.x+60, bounds.origin.y+40, bounds.size.width-75, bounds.size.height-60);
	NSRect b = NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
	
	// Fill the view with Colors
	[bgColor set];
    [NSBezierPath fillRect:r];
	[NSBezierPath fillRect:b];
	[txtColor set];
	[NSBezierPath strokeRect:r];
	
	// nothing drawable: no spread of values or of time (division by zero below), or values that are not numbers
	BOOL drawable = minValueX >= 0 && minValueX < 100 && maxValueX >= 0 && maxValueX < 100
		&& isfinite(maxValueY) && isfinite(minValueY) && (maxValueY - minValueY) != 0
		&& isfinite(timeXHere[maxValueX]) && isfinite(timeXHere[minValueX]) && (timeXHere[maxValueX] - timeXHere[minValueX]) != 0;
	if (flag_blank == 1 || !drawable)
	{
		while (legendName.numberOfRows != 0)
			[legendName removeRow:legendName.numberOfRows-1];
	}
	else
	{
		int numXaxisTmp = 10, numYaxisTmp = 11;
		int numXaxis, numYaxis;
		int stepValue = (int)((maxValueY-minValueY)/(float)numYaxisTmp);
		int stepTime  = (int)((timeXHere[maxValueX]-timeXHere[minValueX])/(float)numXaxisTmp);
        NSLog(@"minValueX = %d, maxValueX = %d, stepTime=%d",minValueX, maxValueX,stepTime);
        
		
		if (stepTime != 0 && stepValue != 0)
		{
			numYaxis = (int)((maxValueY-minValueY)/(float)stepValue);
			numXaxis = (int)((timeXHere[maxValueX]-timeXHere[minValueX])/(float)stepTime);
		}
		else
		{
			numYaxis = numYaxisTmp;
			numXaxis = numXaxisTmp;
		}
		NSLog(@"numXaxis is %d, numYaxis is %d.  stepTime is %d",numXaxis,numYaxis, stepTime);

		
		// Define locations & value for y-axis label 
		for (i = 0; i < numYaxis+1; i++)
		{
			yAxisValue[i] = minValueY+(float)(stepValue*i);
			yAxisLoc[i]   = r.origin.y+r.size.height*(float)(yAxisValue[i]-minValueY)/(float)(maxValueY-minValueY);
		}
		// Define locations & time for x-axis label 
		for (i = 0; i < numXaxis+1; i++)
		{
			xAxisTime[i] = ceil(timeXHere[minValueX])+stepTime*(float)i;
			xAxisLoc[i]  = r.origin.x+r.size.width*(xAxisTime[i]-timeXHere[minValueX])/(timeXHere[maxValueX]-timeXHere[minValueX]);
            NSLog(@"xAxisTime[%d] = %g",i,xAxisTime[i]);
		}
		
		// Draw selected region
		NSLog(@"selectedRegion is %d",selectedRegion);
		if (selectedRegion == 1)
			[self drawSelectedRegion:r];

		// Draw X- and Y-Grid
		if ([gridOn state] == NSOnState) 
		{
			[self drawXGrid:r];
			[self drawYGrid:numYaxis :r];
		}
		
		[self drawPlot:r];
		
		if ([legendOn state] == NSOnState)
			[self drawLegend:r];
		else
		{
			while (legendName.numberOfRows != 0)
				[legendName removeRow:legendName.numberOfRows-1];
		}
		
		
		// Fill the upper and bottom region with white color
		NSRect upper  = NSMakeRect(bounds.origin.x, bounds.origin.y+bounds.size.height-19, bounds.size.width, 19);
		NSRect bottom = NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, 39);
		NSRect right  = NSMakeRect(bounds.origin.x+bounds.size.width-14, bounds.origin.y, 14, bounds.size.height);
		
		// Fill the view with background color
		[bgColor set];
		[NSBezierPath fillRect:upper];
		[NSBezierPath fillRect:bottom];
		[NSBezierPath fillRect:right];
		
		// Redraw the line
		[txtColor set];
		[NSBezierPath strokeRect:r];
		
		// Label X- and Y-axes
		[self drawXAxis:timeXHere :minValueX :maxValueX :numXaxis :stepTime :r];
		[self drawYAxis:minValueY :maxValueY :numYaxis :stepValue :r];
		
		// Name X- and Y-axes
		[self nameAxes];
	}
	NSLog(@"drawRect done!");
}

#pragma mark-
#pragma mark Save  

-(void) dicomSave:(NSString*)seriesDescription backgroundColor:(NSColor*)backgroundColor toFile:(NSString*)filename 
{
	
	NSBitmapImageRep* bitmapImageRep = [self bitmapImageRepForCachingDisplayInRect:[self bounds]];
	[self cacheDisplayInRect:[self bounds] toBitmapImageRep:bitmapImageRep];
	
	NSInteger bytesPerPixel = [bitmapImageRep bitsPerPixel]/8;
	CGFloat backgroundRGBA[4]; [[backgroundColor colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getComponents:backgroundRGBA];
	
	// convert RGBA to RGB - alpha values are considered when mixing the background color with the actual pixel color
	NSMutableData* bitmapRGBData = [NSMutableData dataWithCapacity: [bitmapImageRep size].width*[bitmapImageRep size].height*3];
	
	int x,y;
	for (y = 0; y < [bitmapImageRep size].height; ++y) 
	{
		unsigned char* rowStart = [bitmapImageRep bitmapData]+[bitmapImageRep bytesPerRow]*y;
		for (x = 0; x < [bitmapImageRep size].width; ++x) 
		{
			unsigned char rgba[4]; memcpy(rgba, rowStart+bytesPerPixel*x, 4);
			float ratio = (float)rgba[3]/255;
			// rgba[0], [1] and [2] are premultiplied by [3]
			rgba[0] = rgba[0]+(1-ratio)*backgroundRGBA[0]*255;
			rgba[1] = rgba[1]+(1-ratio)*backgroundRGBA[1]*255;
			rgba[2] = rgba[2]+(1-ratio)*backgroundRGBA[2]*255;
			[bitmapRGBData appendBytes:rgba length:3];
		}
	}
	
	DICOMExport* dicomExport = [[DICOMExport alloc] init];
	[dicomExport setSourceFile:filename];
	[dicomExport setSeriesDescription: seriesDescription];
	[dicomExport setSeriesNumber: 40001];
	[dicomExport setPixelData:(unsigned char*)[bitmapRGBData bytes] samplePerPixel:3 bitsPerPixel:8 width:[bitmapImageRep size].width height:[bitmapImageRep size].height];

//	[dicomExport writeDCMFile:nil];
	NSString *f = [dicomExport writeDCMFile: nil];
	
	if( f)
		[BrowserController addFiles: [NSArray arrayWithObject: f]
						  toContext: [[BrowserController currentBrowser] managedObjectContext]
						 toDatabase: [BrowserController currentBrowser]
						  onlyDICOM: YES 
				   notifyAddedFiles: YES
				parseExistingObject: YES
						   dbFolder: [[BrowserController currentBrowser] documentsDirectory]
				  generatedByOsiriX: YES];
	
	[dicomExport release];
}

- (void) savePDF
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:@"pdf"];
	
	[panel beginSheetForDirectory:nil
							 file:nil
				   modalForWindow:[self window]
					modalDelegate:self
				   didEndSelector:@selector(didPDFEnd:returnCode:contextInfo:)
					  contextInfo:NULL];
}

- (void) saveTXT
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:@"txt"];
	
	[panel beginSheetForDirectory:nil
							 file:nil
				   modalForWindow:[self window]
					modalDelegate:self
				   didEndSelector:@selector(didTXTEnd:returnCode:contextInfo:)
					  contextInfo:NULL];
}

- (void) didPDFEnd:(NSSavePanel *)sheet returnCode:(int)code contextInfo:(void *)contextInfo
{
    if (code != NSOKButton)        return;
	
	NSData *data;
	NSRect r = [self bounds];
	data = [self dataWithPDFInsideRect:r];
	
	NSString *pathTmp = [sheet filename];
	NSError *error;
	BOOL successful = [data writeToFile:pathTmp
								options:0
								  error:&error];
	
	if (!successful) 
	{
		NSAlert *a = [NSAlert alertWithError:error];
		[a runModal];
	}
}

- (void) didTXTEnd:(NSSavePanel *)sheet returnCode:(int)code contextInfo:(void *)contextInfo
{
    if (code != NSOKButton)        return;
	
	NSData *data;
	NSString *line;;
	NSMutableString *lineAll = [NSMutableString stringWithString:@"\n"];
	
	//	// loop over the array, create a string for each line
	//	for (idroi = 0; idroi < numValueROI; idroi++) 
	//	{
	//		[lineAll appendString:[roiNameListHere objectAtIndex:idroi]];
	//		for (i = 0; i < nnTimeHere; i++)
	//		{
	//			line = [NSString stringWithFormat:@"\t %.2f", meanHere[idroi][i], nil];
	//			[lineAll appendString:line];
	//		}
	//		[lineAll appendString:@"\n"];
	//	}
	//	
	//	[lineAll appendString:@"\nSaved Time Points: \n\n"];
	//	for (i = 0; i < nnTimeHere; i++)
	//	{
	//		line = [NSString stringWithFormat:@"\t %.2f", timeXHere[i], nil];
	//		[lineAll appendString:line];
	//	}
	
	[lineAll appendString:@"Time\t"];
	for (idroi = 0; idroi < numValueROI; idroi++) 
	{
		[lineAll appendString:[roiNameListHere objectAtIndex:idroi]];
		[lineAll appendString:@"\t STD\t min\t max\t \t"];
		// STD, min, max
	}
	[lineAll appendString:@"\n"];
	
	// loop over the array, create a string for each line
	for (i = 0; i < nnTimeHere; i++)
	{
		line = [NSString stringWithFormat:@"%.2f\t", timeXHere[i], nil];
		[lineAll appendString:line];
		
		for (idroi = 0; idroi < numValueROI; idroi++) 
		{
			line = [NSString stringWithFormat:@"%.2f\t", meanHere[idroi][i], nil];
			[lineAll appendString:line];
			
			line = [NSString stringWithFormat:@"%.2f\t", stdYHere[idroi][i], nil];
			[lineAll appendString:line];
			line = [NSString stringWithFormat:@"%.1f\t", minimumYHere[idroi][i], nil];
			[lineAll appendString:line];
			line = [NSString stringWithFormat:@"%.1f\t", maximumYHere[idroi][i], nil];
			[lineAll appendString:line];
			[lineAll appendString:@"\t"];
		}
		[lineAll appendString:@"\n"];
	}
	[lineAll appendString:@"\n"];
	
	//NSLog(@"lineAll is %@",lineAll);
	data = [lineAll dataUsingEncoding:NSUTF8StringEncoding];
	
	NSString *pathTmp = [sheet filename];
	NSError *error;
	BOOL successful = [data writeToFile:pathTmp
								options:0
								  error:&error];
	
	if (!successful) 
	{
		NSAlert *a = [NSAlert alertWithError:error];
		[a runModal];
	}
}

- (int) plotContentType
{
    NSLog(@"Plot content type is %ld",(long)typeSignal2.indexOfSelectedItem);
    return typeSignal2.indexOfSelectedItem;
}

- (void) setPlotTitle:(NSString *)title
{
    NSString *titlestr = [[NSString alloc] initWithFormat:@"%@",title];
    plotTitle = titlestr;
}
@end
