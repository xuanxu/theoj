# Changelog

## Unreleased

- Added reviews_repository_url to Journal
- Added article_metadata to Submission
- Added editor and paper dates lookup information in Submission
- Fixed error reading reviewers list from issue body

## 1.1.1 (2021-11-05)

- Added support for test-journal

## 1.1.0 (2021-10-29)

- Added Theoj::PublishedPaper object with metadata from Journal's API
- Added custom Error class

## 1.0.0 (2021-10-20)

- Added method to Journal to create paper_id from issue_id
- Added method to Journal to get a DOI based on a paper id
- Added languages to Paper
- Added authors info to Paper
- Author object
- Added ORCID validation
- Added Submission object, grouping a paper, a review issue and a journal
- Added paper depositing

## 0.0.3 (2021-10-08)

- Added metadata methods to Paper
- Added to ReviewIssue: editor, reviewers, archive, version
- New method to read any value from review's issue body
- Values read from issue boy will be empty if Pending or TBD
- Added journal config data for OpenJournals: JOSS and JOSE


## 0.0.2 (2021-09-22)

- Available objects: Theoj::Journal, Theoj::ReviewIssue and Theoj::Paper


## 0.0.1 (2021-09-22)

- Gem created

